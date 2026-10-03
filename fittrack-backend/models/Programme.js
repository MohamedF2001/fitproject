import mongoose from "mongoose";

const exerciceProgrammeSchema = new mongoose.Schema(
  {
    exerciceId: {
      type: String,
      required: [true, "L'identifiant de l'exercice est obligatoire"],
    },
    ordre: {
      type: Number,
      required: [true, "L'ordre est obligatoire"],
    },
  },
  { _id: false }
);

const jourSchema = new mongoose.Schema(
  {
    jour: {
      type: String,
      enum: ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"],
      required: [true, "Le jour est obligatoire"],
    },
    horaire: {
      type: String,
      required: [true, "L'horaire est obligatoire"],
    },
    exercices: {
      type: [exerciceProgrammeSchema],
      default: [],
    },
  },
  { _id: false }
);

const programmeSchema = new mongoose.Schema(
  {
    utilisateur: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    nom: {
      type: String,
      required: [true, "Le nom du programme est obligatoire"],
    },
    jours: {
      type: [jourSchema],
      default: [],
    },
    actif: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: { createdAt: "dateCreation", updatedAt: false } }
);

programmeSchema.pre("save", async function (next) {
  if (this.actif) {
    await this.constructor.updateMany(
      { utilisateur: this.utilisateur, _id: { $ne: this._id } },
      { $set: { actif: false } }
    );
  }
  next();
});

export default mongoose.model("Programme", programmeSchema);
