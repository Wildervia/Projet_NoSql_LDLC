// Lot 1 - Requêtes types sur le catalogue

use('ldlc');

// R1 - Afficher un produit précis (la fiche produit)
db.produits.findOne({ _id: "P1" });

// R2 - Tous les produits d'une catégorie
db.produits.find({ categorie: "Processeur" });

// R3 - Les produits à moins de 200 €
db.produits.find({ prix: { $lt: 200 } });

// R4 - Chercher DANS les caractéristiques : les produits compatibles AM5
db.produits.find({ "specs.socket": "AM5" });

// R5 - Tous les produits, du moins cher au plus cher
db.produits.find().sort({ prix: 1 });

// R6 - Afficher seulement le nom et le prix
db.produits.find({}, { nom: 1, prix: 1 });

// R7 - Les produits compatibles avec le processeur P1
db.produits.find({ _id: { $in: ["P2", "P3"] } });