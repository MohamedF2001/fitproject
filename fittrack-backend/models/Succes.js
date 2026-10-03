import mongoose from "mongoose";

const succesSchema = new mongoose.Schema({
  utilisateur: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  objectif: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Objectif",
    required: true,
  },
  dateObtention: {
    type: Date,
    default: Date.now,
  },
  description: {
    type: String,
    required: true,
  },
});

export default mongoose.model("Succes", succesSchema);
