let catalogueExercices = [];

export const setCatalogueExercices = (catalogue) => {
  catalogueExercices = catalogue;
};

export const getExercices = async (req, res) => {
  try {
    const { muscle, categorie } = req.query;
    let groupes = catalogueExercices;

    if (muscle) {
      groupes = groupes
        .filter((groupe) => groupe.muscle.toLowerCase() === muscle.toLowerCase())
        .map((groupe) => ({ ...groupe }));
    }

    if (categorie) {
      groupes = groupes
        .map((groupe) => ({
          ...groupe,
          exercices: groupe.exercices.filter(
            (exercice) => exercice.category.toLowerCase() === categorie.toLowerCase()
          ),
        }))
        .filter((groupe) => groupe.exercices.length > 0);
    }

    return res.status(200).json(groupes);
  } catch (error) {
    console.error("❌ Erreur lors de la récupération des exercices :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};

export const getExerciceById = async (req, res) => {
  try {
    const { id } = req.params;

    for (const groupe of catalogueExercices) {
      const exercice = groupe.exercices.find((ex) => ex.id === id || ex.uuid === id);
      if (exercice) {
        return res.status(200).json({ muscle: groupe.muscle, ...exercice });
      }
    }

    return res.status(404).json({ message: "❌ Exercice introuvable" });
  } catch (error) {
    console.error("❌ Erreur lors de la récupération de l'exercice :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};
