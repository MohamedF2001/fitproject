import mongoose from "mongoose";

let cached = global.mongoose;

if (!cached) {
  cached = global.mongoose = { conn: null, promise: null };
}

async function connectDB() {
  if (cached.conn) {
    return cached.conn;
  }

  if (!cached.promise) {
    const opts = {
      serverSelectionTimeoutMS: 10000,
      connectTimeoutMS: 10000,
    };

    const mongoUri = process.env.MONGO_URI;
    cached.promise = mongoose.connect(mongoUri, opts).then((mongoose) => {
      console.log("✅ MongoDB connecté");
      return mongoose;
    });
  }

  try {
    cached.conn = await cached.promise;
  } catch (e) {
    cached.promise = null;
    console.error("❌ Erreur de connexion MongoDB :", e.message);
    throw e;
  }

  return cached.conn;
}

export default connectDB;
