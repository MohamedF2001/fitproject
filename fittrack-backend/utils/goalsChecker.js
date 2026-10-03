import Objectif from "../models/Objectif.js";
import Succes from "../models/Succes.js";
import Seance from "../models/Seance.js";

const PERIODE_REGULARITE_JOURS = 7;

const checkPoidsCible = async (objectif, user) => {
  if (user.poids === null || user.poids === undefined) return false;
  if (objectif.valeurCible === null || objectif.valeurCible === undefined) return false;
  return user.poids <= objectif.valeurCible;
};

const checkRegulariteSeances = async (objectif, user) => {
  if (objectif.valeurCible === null || objectif.valeurCible === undefined) return false;

  const dateDebut = new Date();
  dateDebut.setDate(dateDebut.getDate() - PERIODE_REGULARITE_JOURS);

  const nombreSeances = await Seance.countDocuments({
    utilisateur: user._id,
    statut: "validee",
    valideeLe: { $gte: dateDebut },
  });

  return nombreSeances >= objectif.valeurCible;
};

export const checkGoals = async (user) => {
  try {
    const objectifsEnCours = await Objectif.find({
      utilisateur: user._id,
      statut: "en_cours",
    });

    const succesCrees = [];

    for (const objectif of objectifsEnCours) {
      let atteint = false;

      if (objectif.type === "poids_cible") {
        atteint = await checkPoidsCible(objectif, user);
      } else if (objectif.type === "regularite_seances") {
        atteint = await checkRegulariteSeances(objectif, user);
      }

      if (atteint) {
        objectif.statut = "atteint";
        await objectif.save();

        let description = "Objectif atteint";
        if (objectif.type === "poids_cible") {
          description = `Objectif poids atteint : ${user.poids}kg`;
        } else if (objectif.type === "regularite_seances") {
          description = `Objectif de régularité atteint : ${objectif.valeurCible} séances/semaine`;
        }

        const succes = await Succes.create({
          utilisateur: user._id,
          objectif: objectif._id,
          description,
        });

        succesCrees.push(succes);
        console.log(`✅ Nouveau succès débloqué pour l'utilisateur ${user._id} : ${description}`);
      }
    }

    return succesCrees;
  } catch (error) {
    console.error("❌ Erreur lors de la vérification des objectifs :", error.message);
    return [];
  }
};

export default checkGoals;
