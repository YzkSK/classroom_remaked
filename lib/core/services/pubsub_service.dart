// lib/core/services/pubsub_service.dart
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/pubsub/v1.dart' as pubsub;
import 'package:googleapis/classroom/v1.dart' as classroom;
import '../constants/app_constants.dart';
import '../../data/datasources/local/sync_state_datasource.dart';
import '../../data/datasources/remote/classroom_http_client.dart';

class PubSubService {
  PubSubService({
    required GoogleSignInAccount account,
    required SyncStateDataSource syncState,
  })  : _account = account,
        _syncState = syncState;

  final GoogleSignInAccount _account;
  final SyncStateDataSource _syncState;

  String get _topicName =>
      'projects/${AppConstants.gcpProjectId}/topics/${AppConstants.pubsubTopicId}';
  String get _subscriptionName =>
      'projects/${AppConstants.gcpProjectId}/subscriptions/${AppConstants.pubsubSubscriptionId}';

  pubsub.PubsubApi get _pubsubApi =>
      pubsub.PubsubApi(ClassroomHttpClient(_account));
  classroom.ClassroomApi get _classroomApi =>
      classroom.ClassroomApi(ClassroomHttpClient(_account));

  Future<void> ensureSetup() async {
    final done = await _syncState.get('pubsub_setup');
    if (done == 'true') return;

    await _ensureTopic();
    await _ensureIamPolicy();
    await _ensureSubscription();

    await _syncState.set('pubsub_setup', 'true');
  }

  Future<void> ensureRegistration(String courseId) async {
    const key = 'reg_expiry_';
    final expiryStr = await _syncState.get('$key$courseId');
    if (expiryStr != null) {
      final expiry = DateTime.parse(expiryStr);
      if (expiry.isAfter(DateTime.now().add(const Duration(hours: 1)))) {
        return;
      }
    }

    await _classroomApi.registrations.create(
      classroom.Registration(
        feed: classroom.Feed(
          feedType: 'COURSE_WORK_CHANGES',
          courseWorkChangesInfo:
              classroom.CourseWorkChangesInfo(courseId: courseId),
        ),
        cloudPubsubTopic:
            classroom.CloudPubsubTopic(topicName: _topicName),
      ),
    );

    final expiry = DateTime.now().add(const Duration(days: 7));
    await _syncState.set('$key$courseId', expiry.toIso8601String());
  }

  Future<List<String>> pullChangedCourseIds() async {
    final response = await _pubsubApi.projects.subscriptions.pull(
      pubsub.PullRequest(maxMessages: 100),
      _subscriptionName,
    );

    final messages = response.receivedMessages ?? [];
    if (messages.isEmpty) return [];

    final courseIds = <String>{};
    final ackIds = <String>[];

    for (final msg in messages) {
      if (msg.ackId != null) ackIds.add(msg.ackId!);

      final data = msg.message?.data;
      if (data != null) {
        try {
          final json = jsonDecode(
            utf8.decode(base64.decode(data)),
          ) as Map<String, dynamic>;
          final message = json['message'] as Map<String, dynamic>?;
          final courseId = message?['courseId'] as String?;
          if (courseId != null) courseIds.add(courseId);
        } catch (_) {}
      }
    }

    if (ackIds.isNotEmpty) {
      await _pubsubApi.projects.subscriptions.acknowledge(
        pubsub.AcknowledgeRequest(ackIds: ackIds),
        _subscriptionName,
      );
    }

    return courseIds.toList();
  }

  Future<void> _ensureTopic() async {
    try {
      await _pubsubApi.projects.topics.get(_topicName);
    } catch (_) {
      await _pubsubApi.projects.topics.create(
        pubsub.Topic(name: _topicName),
        _topicName,
      );
    }
  }

  Future<void> _ensureIamPolicy() async {
    await _pubsubApi.projects.topics.setIamPolicy(
      pubsub.SetIamPolicyRequest(
        policy: pubsub.Policy(
          bindings: [
            pubsub.Binding(
              role: 'roles/pubsub.publisher',
              members: [
                'serviceAccount:${AppConstants.classroomServiceAccount}'
              ],
            ),
          ],
        ),
      ),
      _topicName,
    );
  }

  Future<void> _ensureSubscription() async {
    try {
      await _pubsubApi.projects.subscriptions.get(_subscriptionName);
    } catch (_) {
      await _pubsubApi.projects.subscriptions.create(
        pubsub.Subscription(
          name: _subscriptionName,
          topic: _topicName,
          ackDeadlineSeconds: 60,
        ),
        _subscriptionName,
      );
    }
  }
}
