// Lot 1 - Catalogue produits LDLC

use('ldlc');

// On vide la collection pour pouvoir relancer le fichier sans erreur
db.produits.drop();

// On ajoute 5 produits de catégories différentes
db.produits.insertMany([
  {
    _id: "P1",
    nom: "AMD Ryzen 7 7800X3D",
    categorie: "Processeur",
    marque: "AMD",
    prix: 389.95,
    stock: 42,
    specs: { socket: "AM5", coeurs: 8, frequence_ghz: 5.0 },
    compatibles: ["P2", "P3"]
  },
  {
    _id: "P2",
    nom: "MSI MAG B650 TOMAHAWK WIFI",
    categorie: "Carte mère",
    marque: "MSI",
    prix: 219.95,
    stock: 25,
    specs: { socket: "AM5", format: "ATX", memoire: "DDR5", wifi: true },
    compatibles: ["P1", "P3"]
  },
  {
    _id: "P3",
    nom: "Corsair Vengeance DDR5 32 Go",
    categorie: "Mémoire",
    marque: "Corsair",
    prix: 109.95,
    stock: 80,
    specs: { type: "DDR5", capacite_go: 32, frequence_mhz: 6000 },
    compatibles: ["P1", "P2"]
  },
  {
    _id: "P4",
    nom: "Logitech G PRO X SUPERLIGHT 2",
    categorie: "Souris",
    marque: "Logitech",
    prix: 159.95,
    stock: 60,
    specs: { sans_fil: true, dpi_max: 32000, poids_g: 60 },
    compatibles: []
  },
  {
    _id: "P5",
    nom: "Microsoft Windows 11 Famille",
    categorie: "Logiciel",
    marque: "Microsoft",
    prix: 145.00,
    stock: 500,
    specs: { licence: "Clé numérique", nb_postes: 1 },
    compatibles: []
}
]);


// ---------- AVIS CLIENTS (collection séparée) ----------
db.avis.drop();

db.avis.insertMany([
{ _id: "A1", produit_id: "P1", client: "Jean",  note: 5, commentaire: "Parfait pour le gaming", date: new Date("2026-09-02") },
{ _id: "A2", produit_id: "P1", client: "Max",   note: 4, commentaire: "Chauffe un peu",        date: new Date("2026-09-30") },
{ _id: "A3", produit_id: "P1", client: "Léa",   note: 5, commentaire: "Le meilleur CPU",       date: new Date("2026-10-12") },
{ _id: "A4", produit_id: "P4", client: "Sam",   note: 4, commentaire: "Très légère",           date: new Date("2026-08-21") }
]);

// Résumé des avis dans la fiche produit (Computed Pattern)
db.produits.updateOne({ _id: "P1" }, { $set: { nb_avis: 3, total_notes: 14 } });
db.produits.updateOne({ _id: "P4" }, { $set: { nb_avis: 1, total_notes: 4 } });


// ---------- INDEX (pour accélérer les recherches fréquentes) ----------
db.produits.createIndex({ categorie: 1, prix: 1 });   // R2 et R5 : une catégorie triée par prix
db.produits.createIndex({ "specs.socket": 1 });       // R4 : recherche par socket
db.avis.createIndex({ produit_id: 1, date: -1 });     // R8 : les avis d'un produit, du plus récent


// Afficher tous les produits
db.produits.find();

