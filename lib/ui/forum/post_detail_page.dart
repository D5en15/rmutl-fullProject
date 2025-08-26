import 'package:flutter/material.dart';
import '../../services/forum_service.dart';
import '../../models/post.dart';
import '../../models/comment.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late Future<Post> postFuture;
  late Future<List<Comment>> commentsFuture;

  @override
  void initState() {
    super.initState();
    postFuture = ForumService().getPost(widget.postId);
    commentsFuture = ForumService().listComments(widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Post ${widget.postId}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Post>(
          future: postFuture,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final post = snap.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'by ${post.author}',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: [
                      Text(post.content),
                      const SizedBox(height: 16),
                      Text(
                        'Comments',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<List<Comment>>(
                        future: commentsFuture,
                        builder: (_, cSnap) {
                          if (!cSnap.hasData)
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          final comments = cSnap.data!;
                          return Column(
                            children:
                                comments
                                    .map(
                                      (c) => Card(
                                        child: ListTile(
                                          leading: const Icon(
                                            Icons.person_outline,
                                          ),
                                          title: Text(c.author),
                                          subtitle: Text(c.message),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
