import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import bcrypt from "bcryptjs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const storePath = path.join(__dirname, "../data/store.json");

const loadStore = () => {
  try {
    if (fs.existsSync(storePath)) {
      return JSON.parse(fs.readFileSync(storePath, "utf-8"));
    }
  } catch (e) {}
  return { users: [], objectifs: [], programmes: [], seances: [] };
};

const saveStore = (data) => {
  try {
    const dir = path.dirname(storePath);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(storePath, JSON.stringify(data, null, 2));
  } catch (e) {}
};

export const memoryDb = {
  _load: loadStore,
  _save: saveStore,
  users: {
    async findOne(query) {
      const db = loadStore();
      return db.users.find(u =>
        (query.email && u.email === query.email) ||
        (query._id && u._id === query._id)
      ) || null;
    },
    async findById(id) {
      const db = loadStore();
      return db.users.find(u => u._id === id || u.id === id) || null;
    },
    async create(doc) {
      const db = loadStore();
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(doc.motDePasse, salt);
      const newUser = {
        _id: "user_" + Date.now(),
        email: doc.email.toLowerCase(),
        motDePasse: hashedPassword,
        nom: doc.nom || null,
        prenom: doc.prenom || null,
        poids: doc.poids || null,
        taille: doc.taille || null,
        historiquePoids: [],
        createdAt: new Date().toISOString(),
      };
      db.users.push(newUser);
      saveStore(db);
      return {
        ...newUser,
        comparePassword: async (pass) => bcrypt.compare(pass, newUser.motDePasse),
        save: async () => {
          const currentDb = loadStore();
          const idx = currentDb.users.findIndex(u => u._id === newUser._id);
          if (idx >= 0) {
            currentDb.users[idx] = newUser;
            saveStore(currentDb);
          }
        },
        toJSON: () => {
          const obj = { ...newUser };
          delete obj.motDePasse;
          return obj;
        }
      };
    }
  },
  programmes: {
    async find(query) {
      const db = loadStore();
      return db.programmes.filter(p => !query.utilisateur || p.utilisateur === query.utilisateur);
    },
    async findOne(query) {
      const db = loadStore();
      return db.programmes.find(p =>
        (!query.utilisateur || p.utilisateur === query.utilisateur) &&
        (!query._id || p._id === query._id) &&
        (query.actif === undefined || p.actif === query.actif)
      ) || null;
    },
    async findOneAndDelete(query) {
      const db = loadStore();
      const idx = db.programmes.findIndex(p => p._id === query._id && (!query.utilisateur || p.utilisateur === query.utilisateur));
      if (idx >= 0) {
        const removed = db.programmes.splice(idx, 1)[0];
        saveStore(db);
        return removed;
      }
      return null;
    },
    async updateMany(query, update) {
      const db = loadStore();
      db.programmes.forEach(p => {
        if (!query.utilisateur || p.utilisateur === query.utilisateur) {
          if (update.$set && update.$set.actif !== undefined) {
            p.actif = update.$set.actif;
          }
        }
      });
      saveStore(db);
    }
  },
  objectifs: {
    async find(query) {
      const db = loadStore();
      return db.objectifs.filter(o =>
        (!query.utilisateur || o.utilisateur === query.utilisateur) &&
        (!query.statut || o.statut === query.statut)
      );
    }
  }
};
