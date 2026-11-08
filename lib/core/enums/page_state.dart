enum PageState {
  loading("Loading"),
  loaded("Loaded"),
  error("Error"),
  empty("Empty");

  const PageState(this.state);
  final String state;
}
