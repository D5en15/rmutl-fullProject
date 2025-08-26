import '../models/post.dart';
import '../models/comment.dart';

class ForumService {
  Future<List<Post>> listPosts() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const [
      Post(
        id: 'p1',
        title: 'ยินดีต้อนรับ',
        content: 'ประกาศเปิดเทอม',
        author: 'admin',
      ),
      Post(
        id: 'p2',
        title: 'Lab 1 แนวทาง',
        content: 'แนบตัวอย่างไฟล์',
        author: 'teacherA',
      ),
    ];
  }

  Future<Post> getPost(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return Post(
      id: id,
      title: 'หัวข้อ $id',
      content: 'รายละเอียดโพสต์ $id',
      author: 'userX',
    );
  }

  Future<List<Comment>> listComments(String postId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    return [
      Comment(
        id: 'c1',
        postId: postId,
        author: 'stud01',
        message: 'ขอบคุณครับ!',
      ),
      Comment(
        id: 'c2',
        postId: postId,
        author: 'stud02',
        message: 'สอบเมื่อไหร่ครับ',
      ),
    ];
  }
}
