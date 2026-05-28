import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { defineSecret } from "firebase-functions/params";
import * as crypto from "crypto";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();
const REGION = "asia-northeast1";

const ENCRYPTION_KEY = defineSecret("ENCRYPTION_KEY");
const OAUTH_CLIENT_ID = defineSecret("OAUTH_CLIENT_ID");
const OAUTH_CLIENT_SECRET = defineSecret("OAUTH_CLIENT_SECRET");

interface Assignment {
  id: string;
  courseId: string;
  courseName: string;
  title: string;
  dueStr?: string;
}

function encrypt(text: string, keyHex: string): string {
  const key = Buffer.from(keyHex, "hex");
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv("aes-256-gcm", key, iv);
  const encrypted = Buffer.concat([cipher.update(text, "utf8"), cipher.final()]);
  const tag = cipher.getAuthTag();
  return Buffer.concat([iv, tag, encrypted]).toString("base64");
}

function decrypt(data: string, keyHex: string): string {
  const buf = Buffer.from(data, "base64");
  const iv = buf.subarray(0, 16);
  const tag = buf.subarray(16, 32);
  const encrypted = buf.subarray(32);
  const key = Buffer.from(keyHex, "hex");
  const decipher = crypto.createDecipheriv("aes-256-gcm", key, iv);
  decipher.setAuthTag(tag);
  return decipher.update(encrypted).toString("utf8") + decipher.final("utf8");
}

async function refreshAccessToken(
  refreshToken: string,
  clientId: string,
  clientSecret: string
): Promise<string> {
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "refresh_token",
      refresh_token: refreshToken,
      client_id: clientId,
      client_secret: clientSecret,
    }).toString(),
  });
  const data = (await res.json()) as { access_token?: string; error?: string };
  if (!data.access_token) throw new Error(`Token refresh failed: ${data.error}`);
  return data.access_token;
}

async function fetchNewAssignments(
  accessToken: string,
  alreadyNotifiedIds: string[],
  asTeacher: boolean
): Promise<Assignment[]> {
  const auth = `Bearer ${accessToken}`;
  const filter = asTeacher ? "teacherId=me" : "studentId=me";
  const coursesRes = await fetch(
    `https://classroom.googleapis.com/v1/courses?courseStates=ACTIVE&${filter}&pageSize=50`,
    { headers: { Authorization: auth } }
  );
  const coursesData = (await coursesRes.json()) as {
    courses?: Array<{ id: string; name: string }>;
  };
  const courses = coursesData.courses ?? [];

  const notifiedSet = new Set(alreadyNotifiedIds);
  const results: Assignment[] = [];

  for (const course of courses) {
    const worksRes = await fetch(
      `https://classroom.googleapis.com/v1/courses/${course.id}/courseWork?courseWorkStates=PUBLISHED&orderBy=updateTime+desc&pageSize=30`,
      { headers: { Authorization: auth } }
    );
    const worksData = (await worksRes.json()) as {
      courseWork?: Array<{
        id: string;
        title: string;
        dueDate?: { year?: number; month?: number; day?: number };
        dueTime?: { hours?: number; minutes?: number };
      }>;
    };

    for (const work of worksData.courseWork ?? []) {
      if (notifiedSet.has(work.id)) continue;

      let dueStr: string | undefined;
      if (work.dueDate?.year && work.dueDate.month && work.dueDate.day) {
        const due = new Date(
          Date.UTC(
            work.dueDate.year,
            work.dueDate.month - 1,
            work.dueDate.day,
            work.dueTime?.hours ?? 23,
            work.dueTime?.minutes ?? 59,
            0
          )
        );
        dueStr = new Intl.DateTimeFormat("ja-JP", {
          timeZone: "Asia/Tokyo",
          year: "numeric",
          month: "2-digit",
          day: "2-digit",
          hour: "2-digit",
          minute: "2-digit",
        }).format(due);
      }

      results.push({
        id: work.id,
        courseId: course.id,
        courseName: course.name,
        title: work.title,
        dueStr,
      });
    }
  }

  return results;
}

async function pollForUser(
  doc: admin.firestore.QueryDocumentSnapshot,
  encKey: string,
  clientId: string,
  clientSecret: string,
  asTeacher: boolean
): Promise<void> {
  const data = doc.data();
  const encRefreshToken = data.refreshToken as string | undefined;
  const fcmToken = data.fcmToken as string | undefined;
  const notifiedIds: string[] = data.notifiedAssignmentIds ?? [];

  if (!encRefreshToken || !fcmToken) return;

  const refreshToken = decrypt(encRefreshToken, encKey);
  const accessToken = await refreshAccessToken(refreshToken, clientId, clientSecret);
  const newAssignments = await fetchNewAssignments(accessToken, notifiedIds, asTeacher);

  const sentIds: string[] = [];
  for (const assignment of newAssignments) {
    const body = [
      assignment.title,
      assignment.dueStr ? `締め切り: ${assignment.dueStr}` : null,
    ]
      .filter(Boolean)
      .join("\n");

    try {
      await messaging.send({
        token: fcmToken,
        notification: {
          title: assignment.courseName || "新しい課題",
          body: body || undefined,
        },
        apns: { payload: { aps: { sound: "default", badge: 1 } } },
        android: {
          priority: "high",
          notification: { sound: "default", channelId: "new_assignments" },
        },
      });
      sentIds.push(assignment.id);
    } catch (e) {
      console.error(`FCM send failed for ${assignment.id}:`, e);
    }
  }

  if (sentIds.length > 0) {
    const merged = [...new Set([...notifiedIds, ...sentIds])];
    await doc.ref.update({ notifiedAssignmentIds: merged.slice(-500) });
  }
}

export const registerToken = onCall(
  {
    region: REGION,
    secrets: [ENCRYPTION_KEY, OAUTH_CLIENT_ID, OAUTH_CLIENT_SECRET],
  },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Not authenticated");
    const uid = request.auth.uid;
    const { serverAuthCode, fcmToken } = request.data as {
      serverAuthCode: string;
      fcmToken: string;
    };

    const res = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "authorization_code",
        code: serverAuthCode,
        client_id: OAUTH_CLIENT_ID.value(),
        client_secret: OAUTH_CLIENT_SECRET.value(),
        redirect_uri: "",
      }).toString(),
    });
    const tokenData = (await res.json()) as {
      refresh_token?: string;
      error?: string;
      error_description?: string;
    };
    if (!tokenData.refresh_token) {
      throw new HttpsError(
        "internal",
        `Token exchange failed: ${tokenData.error_description ?? tokenData.error}`
      );
    }

    const encRefreshToken = encrypt(tokenData.refresh_token, ENCRYPTION_KEY.value());
    await db.collection("users").doc(uid).set(
      {
        fcmToken,
        refreshToken: encRefreshToken,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return { success: true };
  }
);

export const pollClassroom = onSchedule(
  {
    schedule: "every 15 minutes",
    region: REGION,
    secrets: [ENCRYPTION_KEY, OAUTH_CLIENT_ID, OAUTH_CLIENT_SECRET],
  },
  async () => {
    const encKey = ENCRYPTION_KEY.value();
    const clientId = OAUTH_CLIENT_ID.value();
    const clientSecret = OAUTH_CLIENT_SECRET.value();

    const snapshot = await db.collection("users").get();
    await Promise.allSettled(
      snapshot.docs.map((doc) =>
        pollForUser(doc, encKey, clientId, clientSecret, false)
      )
    );
  }
);

export const debugPollNow = onCall(
  {
    region: REGION,
    secrets: [ENCRYPTION_KEY, OAUTH_CLIENT_ID, OAUTH_CLIENT_SECRET],
  },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Not authenticated");
    const uid = request.auth.uid;
    const asTeacher =
      (request.data as { asTeacher?: boolean })?.asTeacher ?? false;

    const doc = await db.collection("users").doc(uid).get();
    if (!doc.exists) {
      throw new HttpsError(
        "not-found",
        "User not registered (sign out and back in)"
      );
    }

    const encKey = ENCRYPTION_KEY.value();
    const clientId = OAUTH_CLIENT_ID.value();
    const clientSecret = OAUTH_CLIENT_SECRET.value();

    await pollForUser(
      doc as admin.firestore.QueryDocumentSnapshot,
      encKey,
      clientId,
      clientSecret,
      asTeacher
    );
    return { success: true };
  }
);
