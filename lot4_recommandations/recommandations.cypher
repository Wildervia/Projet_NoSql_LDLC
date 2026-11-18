

// 1. Contraintes d'unicité
CREATE CONSTRAINT produit_id_unique IF NOT EXISTS FOR (p:Produit) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT categorie_nom_unique IF NOT EXISTS FOR (c:Categorie) REQUIRE c.nom IS UNIQUE;
CREATE CONSTRAINT marque_nom_unique IF NOT EXISTS FOR (m:Marque) REQUIRE m.nom IS UNIQUE;

// 2. Produits : mêmes identifiants, noms et prix que le Lot 1 MongoDB
MERGE (p1:Produit {id:'P1'}) SET p1.nom='AMD Ryzen 7 7800X3D', p1.prix=389.95, p1.stock=42;
MERGE (p2:Produit {id:'P2'}) SET p2.nom='MSI MAG B650 TOMAHAWK WIFI', p2.prix=219.95, p2.stock=25;
MERGE (p3:Produit {id:'P3'}) SET p3.nom='Corsair Vengeance DDR5 32 Go', p3.prix=109.95, p3.stock=80;
MERGE (p4:Produit {id:'P4'}) SET p4.nom='Logitech G PRO X SUPERLIGHT 2', p4.prix=159.95, p4.stock=60;
MERGE (p5:Produit {id:'P5'}) SET p5.nom='Microsoft Windows 11 Famille', p5.prix=145.00, p5.stock=500;

// 3. Catégories et marques
UNWIND ['Processeur','Carte mère','Mémoire','Souris','Logiciel'] AS nom
MERGE (:Categorie {nom:nom});
UNWIND ['AMD','MSI','Corsair','Logitech','Microsoft'] AS nom
MERGE (:Marque {nom:nom});

// 4. Rattachement aux catégories et aux marques
UNWIND [
 {id:'P1',cat:'Processeur',marque:'AMD'},
 {id:'P2',cat:'Carte mère',marque:'MSI'},
 {id:'P3',cat:'Mémoire',marque:'Corsair'},
 {id:'P4',cat:'Souris',marque:'Logitech'},
 {id:'P5',cat:'Logiciel',marque:'Microsoft'}
] AS ligne
MATCH (p:Produit {id:ligne.id})
MATCH (c:Categorie {nom:ligne.cat})
MATCH (m:Marque {nom:ligne.marque})
MERGE (p)-[:APPARTIENT_A]->(c)
MERGE (p)-[:FABRIQUE_PAR]->(m);

// 5. Compatibilité : relations orientées dans les deux sens pour faciliter la lecture
// P1-P2 : processeur et carte mère AM5 ; P2-P3 : carte mère et mémoire DDR5.
// P1-P3 : association de configuration de démonstration, à valider en production.
UNWIND [['P1','P2'],['P2','P3'],['P1','P3']] AS paire
MATCH (a:Produit {id:paire[0]}), (b:Produit {id:paire[1]})
MERGE (a)-[:COMPATIBLE_AVEC]->(b)
MERGE (b)-[:COMPATIBLE_AVEC]->(a);

// 6. Similarité : score fictif pour illustrer la recommandation (pas issu d'un calcul réel)
// Les 5 produits initiaux appartiennent à des catégories différentes :
// on ne crée pas artificiellement de relation SIMILAIRE_A entre eux.
// La requête de similarité est fournie dans requetes.cypher et fonctionnera
// dès que des produits comparables seront ajoutés.

// 7. Achats groupés : données de démonstration, pas des statistiques Cassandra réelles
UNWIND [
 {a:'P1',b:'P2',n:18},
 {a:'P1',b:'P3',n:12},
 {a:'P2',b:'P3',n:9},
 {a:'P4',b:'P5',n:3}
] AS ligne
MATCH (a:Produit {id:ligne.a}), (b:Produit {id:ligne.b})
MERGE (a)-[r:ACHETE_AVEC]->(b) SET r.nombre_achats=ligne.n
MERGE (b)-[s:ACHETE_AVEC]->(a) SET s.nombre_achats=ligne.n;

// 8. Vérification : afficher le graphe
MATCH (n)-[r]->(m) RETURN n,r,m LIMIT 100;
