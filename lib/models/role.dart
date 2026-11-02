enum Role {
  reader(1, 'Читатель'),
  librarian(2, 'Библиотекарь'),
  admin(3, 'Администратор');

  final int level;
  final String title;
  const Role(this.level, this.title);

  static Role fromString(String? val) {
    return switch (val?.toLowerCase()) {
      'admin' => Role.admin,
      'librarian' => Role.librarian,
      _ => Role.reader,
    };
  }
}
