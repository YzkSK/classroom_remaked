import * as admin from "firebase-admin";
import { onMessagePublished } from "firebase-functions/v2/pubsub";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

interface ClassroomFeedItem {
  courseId?: string;
  courseWorkId?: string;
  announcementId?: string;
  eventType?: string;
}

interface PubSubMessage {
  feed?: {
    feedType?: string;
    courseWorkChangesInfo?: { courseId?: string };
    courseRosterChangesInfo?: { courseId?: string };
  };
  eventType?: string;
  courseWork?: ClassroomFeedItem;
  announcement?: ClassroomFeedItem;
  registrationId?: string;
}

/**
 * Google Classroom Pub/Sub push subscription endpoint.
 *
 * Classroom sends a push message when:
 *   - COURSE_WORK_CHANGES (new assignment/material posted)
 *   - ANNOUNCEMENTS_CHANGES (new announcement)
 *
 * We look up all FCM tokens subscribed to that courseId and send a
 * data-only FCM message so the Flutter app can decide how to display it.
 */
export const classroomWebhook = onMessagePublished(
  { topic: "classroom-notifications", region: "asia-northeast1" },
  async (event) => {
    const raw = event.data.message.data
      ? Buffer.from(event.data.message.data, "base64").toString("utf8")
      : "{}";

    let payload: PubSubMessage;
    try {
      payload = JSON.parse(raw) as PubSubMessage;
    } catch {
      console.warn("Failed to parse Pub/Sub message:", raw);
      return;
    }

    const feedType = payload.feed?.feedType;
    const courseId =
      payload.feed?.courseWorkChangesInfo?.courseId ??
      payload.feed?.courseRosterChangesInfo?.courseId;

    if (!courseId) {
      console.log("No courseId in message, skipping.");
      return;
    }

    // Determine notification content based on feed type
    let title = "新しいお知らせ";
    let body = "Google Classroom に新しい投稿があります";
    if (feedType === "COURSE_WORK_CHANGES") {
      title = "新しい課題";
      body = "新しい課題が投稿されました";
    } else if (feedType === "ANNOUNCEMENTS_CHANGES") {
      title = "新しいお知らせ";
      body = "新しいお知らせが投稿されました";
    }

    // Find all FCM tokens subscribed to this courseId
    const snapshot = await db
      .collection("fcmTokens")
      .where("courseIds", "array-contains", courseId)
      .get();

    if (snapshot.empty) {
      console.log(`No tokens for courseId=${courseId}`);
      return;
    }

    const tokens = snapshot.docs.map((d) => d.id);
    console.log(`Sending to ${tokens.length} token(s) for courseId=${courseId}`);

    // Send multicast FCM message
    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: { courseId, feedType: feedType ?? "" },
      apns: {
        payload: {
          aps: { sound: "default", badge: 1 },
        },
      },
      android: {
        priority: "high",
        notification: { sound: "default", channelId: "deadlines" },
      },
    });

    // Clean up stale tokens
    const staleTokens: string[] = [];
    response.responses.forEach((r, i) => {
      if (!r.success) {
        const code = r.error?.code;
        if (
          code === "messaging/invalid-registration-token" ||
          code === "messaging/registration-token-not-registered"
        ) {
          staleTokens.push(tokens[i]);
        }
      }
    });

    if (staleTokens.length > 0) {
      const batch = db.batch();
      staleTokens.forEach((t) =>
        batch.delete(db.collection("fcmTokens").doc(t))
      );
      await batch.commit();
      console.log(`Deleted ${staleTokens.length} stale token(s)`);
    }

    console.log(
      `Success: ${response.successCount}, Fail: ${response.failureCount}`
    );
  }
);
