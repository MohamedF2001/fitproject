import mongoose from "mongoose";
import bcrypt from "bcryptjs";

const userSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: [true, "L'email est obligatoire"],
      unique: true,
      lowercase: true,
      trim: true,
    },
    motDePasse: {
      type: String,
      required: [true, "Le mot de passe est obligatoire"],
      minlength: [6, "Le mot de passe doit contenir au moins 6 caractères"],
    },
    nom: {
      type: String,
      default: null,
    },
    prenom: {
      type: String,
      default: null,
    },
    poids: {
      type: Number,
      default: null,
    },
    taille: {
      type: Number,
      default: null,
    },
    historiquePoids: [
      {
        poids: {
          type: Number,
          required: true,
        },
        date: {
          type: Date,
          default: Date.now,
        },
      },
    ],
  },
  { timestamps: true }
);

userSchema.pre("save", async function (next) {
  if (!this.isModified("motDePasse")) return next();
  try {
    const salt = await bcrypt.genSalt(10);
    this.motDePasse = await bcrypt.hash(this.motDePasse, salt);
    next();
  } catch (error) {
    next(error);
  }
});

userSchema.methods.comparePassword = async function (motDePasseSaisi) {
  return bcrypt.compare(motDePasseSaisi, this.motDePasse);
};

userSchema.methods.toJSON = function () {
  const user = this.toObject();
  delete user.motDePasse;
  return user;
};

export default mongoose.model("User", userSchema);
