import mongoose from "mongoose";

const serieSchema = new mongoose.Schema(
  {
    numero: {
      type: Number,
      required: [true, "Le numéro de série est obligatoire"],
    },
    repetitions: {
      type: Number,
      required: [true, "Le nombre de répétitions est obligatoire"],
    },
    charge: {
      type: Number,
      default: 0,
    },
  },
  { _id: false }
);

const exerciceSeanceSchema = new mongoose.Schema(
  {
    exerciceId: {
      type: String,
      required: [true, "L'identifiant de l'exercice est obligatoire"],
    },
    series: {
      type: [serieSchema],
      default: [],
    },
    tempsRepos: {
      type: Number,
      default: 60,
    },
  },
  { _id: false }
);

const seanceSchema = new mongoose.Schema(
  {
    utilisateur: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    date: {
      type: Date,
      required: [true, "La date de la séance est obligatoire"],
      default: Date.now,
    },
    exercices: {
      type: [exerciceSeanceSchema],
      default: [],
    },
    statut: {
      type: String,
      enum: ["brouillon", "validee"],
      default: "brouillon",
    },
    valideeLe: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

export default mongoose.model("Seance", seanceSchema);
