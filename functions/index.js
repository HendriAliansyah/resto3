const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore} = require("firebase-admin/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https"); // Import for Callable Functions

initializeApp();

/**
 * A Cloud Function that triggers whenever a document in the 'users'
 * collection is updated, keeping the user's status in sync.
 */
exports.onUserStatusChange = onDocumentUpdated("users/{userId}", async (event) => {
  // Get the data from before and after the change.
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  const uid = event.params.userId;

  // Exit if the 'isDisabled' field hasn't actually changed.
  if (beforeData.isDisabled === afterData.isDisabled) {
    return null;
  }

  // Case 1: The user was just DISABLED.
  if (afterData.isDisabled === true) {
    try {
      // Revoke the user's refresh tokens to force them to log out.
      await getAuth().revokeRefreshTokens(uid);

      // Also, update the user's disabled status in Firebase Auth itself.
      await getAuth().updateUser(uid, {disabled: true});
    } catch (error) {
      console.error(`Error disabling user ${uid}`, error);
    }
  }
  // Case 2: The user was just RE-ENABLED.
  else if (afterData.isDisabled === false) {
    console.log(`Enabling user in Firebase Auth: ${uid}`);
    try {
      // Update the user's disabled status in Firebase Auth.
      await getAuth().updateUser(uid, {disabled: false});
    } catch (error) {
      console.error(`Error enabling user ${uid}`, error);
    }
  }

  return null;
});

exports.requestToJoinRestaurant = onCall(async (request) => {
  const {restaurantId} = request.data;
  const user = request.auth;

  // Ensure the user is authenticated.
  if (!user) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }

  const db = getFirestore();

  // 1. First, check if the restaurant document actually exists.
  const restaurantRef = db.collection("restaurants").doc(restaurantId);
  const restaurantDoc = await restaurantRef.get();

  if (!restaurantDoc.exists) {
    // If the restaurant doesn't exist, throw an error back to the client.
    throw new HttpsError(
        "not-found",
        "No restaurant with this ID exists.",
        {reason: "RESTAURANT_NOT_FOUND"}, // Custom details payload
    );
  }

  // 2. If it exists, proceed with creating the Join Request document.
  const userProfile = (await db.collection("users").doc(user.uid).get()).data();
  const joinRequest = {
    userId: user.uid,
    userDisplayName: userProfile.displayName || "No Name",
    userEmail: user.token.email,
    status: "pending",
    createdAt: new Date(),
  };
  await restaurantRef.collection("joinRequests").doc(user.uid).set(joinRequest);

  // 2. Find all owners and admins of the restaurant.
  const adminQuery = await db.collection("users")
      .where("restaurantId", "==", restaurantId)
      .where("role", "in", ["owner", "admin"])
      .get();

  if (adminQuery.empty) {
    console.log("No admins found for restaurant:", restaurantId);
    return {success: true};
  }

  // 3. Create a notification for each admin.
  const batch = db.batch();
  const notificationPayload = {
    title: "New Join Request",
    type: "joinRequest",
    createdAt: new Date(),
    isRead: false,
    body: `${userProfile.displayName} has requested to join your restaurant.`,
  };

  adminQuery.docs.forEach((adminDoc) => {
    const notificationRef = adminDoc.ref.collection("notifications").doc();
    batch.set(notificationRef, notificationPayload);
  });

  // 4. Commit the batch write.
  await batch.commit();

  return {success: true};
});
