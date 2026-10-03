import mongoose from "mongoose";

const questionMotivationSchema = new mongoose.Schema(
  {
    question: {
      type: String,
      required: true,
    },
    reponse: {
      type: String,
      default: "",
    },
  },
  { _id: false }
);

const objectifSchema = new mongoose.Schema(
  {
    utilisateur: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    type: {
      type: String,
      required: [true, "Le type d'objectif est obligatoire"],
    },
    valeurCible: {
      type: Number,
      default: null,
    },
    questionsMotivation: {
      type: [questionMotivationSchema],
      default: [],
    },
    statut: {
      type: String,
      enum: ["en_cours", "atteint", "abandonne"],
      default: "en_cours",
    },
    dateCible: {
      type: Date,
      default: null,
    },
  },
  { timestamps: { createdAt: "dateCreation", updatedAt: false } }
);

export default mongoose.model("Objectif", objectifSchema);
