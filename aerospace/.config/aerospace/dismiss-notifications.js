// Close all notifications that show on the screen.
//
// The script finds the "Close" and "Clear All" actions in the window tree of
// the NotificationCenter process, and runs them. These are the same actions
// as the X button that shows when you move the mouse over a notification.
//
// Run: osascript -l JavaScript dismiss-notifications.js
// The process that starts the script must have Accessibility permission.

// Action descriptions to run. A "Clear All" action closes a full stack.
// Note: macOS shows these words in the language of the system.
const ACTIONS = ["Clear All", "Close"];

// Stop the search below this depth. This keeps the search fast.
const MAX_DEPTH = 10;

// Stop after this number of actions. This prevents an endless loop when an
// action does not remove its notification.
const MAX_ACTIONS = 50;

function findAction(element, depth) {
  let actions = [];
  try {
    actions = element.actions();
  } catch (e) {}
  for (const wanted of ACTIONS) {
    for (const action of actions) {
      let description = "";
      try {
        description = action.description();
      } catch (e) {}
      if (description === wanted) return action;
    }
  }

  if (depth >= MAX_DEPTH) return null;

  // A notification is a group. Groups and scroll areas contain the
  // notifications. Do not search other elements: each call to System Events
  // is slow.
  let children = [];
  try {
    children = element.groups().concat(element.scrollAreas());
  } catch (e) {}
  for (const child of children) {
    const found = findAction(child, depth + 1);
    if (found) return found;
  }
  return null;
}

function nextAction(process) {
  for (const window of process.windows()) {
    const found = findAction(window, 0);
    if (found) return found;
  }
  return null;
}

function run() {
  const process = Application("System Events").processes.byName(
    "NotificationCenter",
  );
  if (!process.exists()) return;

  // An action changes the window tree, so search again after each action.
  for (let count = 0; count < MAX_ACTIONS; count++) {
    const action = nextAction(process);
    if (!action) return;
    action.perform();
    delay(0.1);
  }
}
