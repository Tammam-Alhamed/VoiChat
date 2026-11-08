enum ProfilePageState {
  loading("Loading"),
  loaded("Loaded"),
  error("Error"),
  empty("Empty"),
  blocked("Blocked"),
  banned("Banned");

  const ProfilePageState(this.state);
  final String state;
}
