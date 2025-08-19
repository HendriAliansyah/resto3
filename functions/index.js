
const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onValueWritten} = require("firebase-functions/v2/database");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore} = require("firebase-admin/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");

initializeApp();

// This new function will handle session cleanup reliably.
exports.onUserPresenceChange = onValueWritten("status/{uid}", async (event) => {
  const firestore = getFirestore();
  const uid = event.params.uid;
  const status = event.data.after.val();

  // If the user has gone offline, clear their session token in Firestore.
  if (status && status.state === "offline") {
    try {
      await firestore.collection("users").doc(uid).update({
        sessionToken: null,
      });
      console.log(`Session token cleared for user: ${uid}`);
    } catch (error) {
      console.error(`Failed to clear session token for user: ${uid}`, error);
    }
  }
});

exports.onUserStatusChange = onDocumentUpdated("users/{userId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  const uid = event.params.userId;

  if (beforeData.isDisabled === afterData.isDisabled) {
    return null;
  }

  if (afterData.isDisabled === true) {
    try {
      await getAuth().revokeRefreshTokens(uid);
      await getAuth().updateUser(uid, {disabled: true});
    } catch (error) {
      console.error(`Error disabling user ${uid}`, error);
    }
  } else if (afterData.isDisabled === false) {
    console.log(`Enabling user in Firebase Auth: ${uid}`);
    try {
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

  if (!user) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }

  const db = getFirestore();
  const restaurantRef = db.collection("restaurants").doc(restaurantId);
  const restaurantDoc = await restaurantRef.get();

  if (!restaurantDoc.exists) {
    throw new HttpsError(
        "not-found",
        "No restaurant with this ID exists.",
        {reason: "RESTAURANT_NOT_FOUND"},
    );
  }

  const userProfile = (await db.collection("users").doc(user.uid).get()).data();
  const joinRequest = {
    userId: user.uid,
    userDisplayName: userProfile.displayName || "No Name",
    userEmail: user.token.email,
    status: "pending",
    createdAt: new Date(),
  };
  await restaurantRef.collection("joinRequests").doc(user.uid).set(joinRequest);

  const adminQuery = await db.collection("users")
      .where("restaurantId", "==", restaurantId)
      .where("role", "in", ["owner", "admin"])
      .get();

  if (adminQuery.empty) {
    console.log("No admins found for restaurant:", restaurantId);
    return {success: true};
  }

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

  await batch.commit();

  return {success: true};
});
