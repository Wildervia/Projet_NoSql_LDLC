// Lot 1 - Requêtes types sur le catalogue

use('ldlc');

// R1 - Afficher un produit précis (la fiche produit)
db.produits.findOne({ _id: "P1" });

use('ldlc');
// R2 - Tous les produits d'une catégorie
db.produits.find({ categorie: "Processeur" });

use('ldlc');
// R3 - Les produits à moins de 200 €
db.produits.find({ prix: { $lt: 200 } });

use('ldlc');
// R4 - Chercher DANS les caractéristiques : les produits compatibles AM5
db.produits.find({ "specs.socket": "AM5" });

use('ldlc');
// R5 - Tous les produits, du moins cher au plus cher
db.produits.find().sort({ prix: 1 });

use('ldlc');
// R6 - Afficher seulement le nom et le prix
db.produits.find({}, { nom: 1, prix: 1 });

use('ldlc');

// R7 - Les produits compatibles avec le processeur P1
db.produits.find({ _id: { $in: ["P2", "P3"] } });

use('ldlc');

// R8 - Les avis d'un produit, du plus récent au plus ancien
db.avis.find({ produit_id: "P1" }).sort({ date: -1 });

use('ldlc');

// R9 - Un client ajoute un avis : 2 actions
db.avis.insertOne({ _id: "A5", produit_id: "P2", client: "Nina", note: 5, commentaire: "Très complète", date: new Date() });
db.produits.updateOne({ _id: "P2" }, { $inc: { nb_avis: 1, total_notes: 5 } });

use('ldlc');

// R10 - La note moyenne de chaque produit (calculée à partir des avis)
db.avis.aggregate([
{ $group: { _id: "$produit_id", note_moyenne: { $avg: "$note" }, nombre: { $sum: 1 } } }
]);

use('ldlc');
// R11 - Voir la liste des index
db.produits.getIndexes();

use('ldlc');

// R12 - Vérifier que la recherche utilise bien l'index
db.produits.find({ categorie: "Processeur" }).sort({ prix: 1 }).explain();

