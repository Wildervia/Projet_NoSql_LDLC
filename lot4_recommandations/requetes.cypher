

// R1 — Afficher les produits du graphe
MATCH (p:Produit) RETURN p.id AS id, p.nom AS nom, p.prix AS prix ORDER BY id;

// R2 — Produits compatibles avec le processeur P1
MATCH (:Produit {id:'P1'})-[:COMPATIBLE_AVEC]->(reco:Produit)
RETURN reco.id AS id, reco.nom AS produit, reco.prix AS prix ORDER BY prix;

// R3 — Produits achetés avec P1, classés par fréquence
MATCH (:Produit {id:'P1'})-[r:ACHETE_AVEC]->(reco:Produit)
RETURN reco.id AS id, reco.nom AS produit, r.nombre_achats AS achats_communs
ORDER BY achats_communs DESC;

// R4 — Produits similaires à P1 (aucun résultat avec les 5 produits de départ)
MATCH (:Produit {id:'P1'})-[r:SIMILAIRE_A]->(reco:Produit)
RETURN reco.id AS id, reco.nom AS produit, r.score AS score
ORDER BY score DESC;

// R5 — Recommandations mixtes pour P1 : compatibilité et achats groupés
MATCH (source:Produit {id:'P1'})-[r:COMPATIBLE_AVEC|ACHETE_AVEC]->(reco:Produit)
WITH reco,
     max(CASE WHEN type(r)='COMPATIBLE_AVEC' THEN 1 ELSE 0 END) AS compatible,
     max(CASE WHEN type(r)='ACHETE_AVEC' THEN r.nombre_achats ELSE 0 END) AS achats
RETURN reco.id AS id, reco.nom AS produit, compatible, achats,
       (compatible * 100 + achats) AS score
ORDER BY score DESC, id;

// R6 — Produits appartenant à la catégorie 'Carte mère'
MATCH (p:Produit)-[:APPARTIENT_A]->(:Categorie {nom:'Carte mère'})
RETURN p.id AS id, p.nom AS produit;

// R7 — Produits fabriqués par AMD
MATCH (p:Produit)-[:FABRIQUE_PAR]->(:Marque {nom:'AMD'})
RETURN p.id AS id, p.nom AS produit;

// R8 — Découverte à deux sauts de compatibilité, sans recommander le produit de départ
MATCH (depart:Produit {id:'P1'})-[:COMPATIBLE_AVEC*2]->(reco:Produit)
WHERE reco <> depart
RETURN DISTINCT reco.id AS id, reco.nom AS produit ORDER BY id;

// R9 — Vérifier le nombre de nœuds par type
MATCH (n) RETURN labels(n) AS type, count(*) AS total ORDER BY type;

// R10 — Vérifier le nombre de relations par type
MATCH ()-[r]->() RETURN type(r) AS relation, count(*) AS total ORDER BY relation;

// R11 — Démonstration de SIMILAIRE_A : ajouter un second processeur
// (produit supplémentaire fictif, absent du Lot 1 ; à exécuter seulement pour le test)
MERGE (p:Produit {id:'P6'}) SET p.nom='Processeur AM5 de démonstration', p.prix=349.95, p.stock=10;
MATCH (p:Produit {id:'P6'}), (c:Categorie {nom:'Processeur'}), (m:Marque {nom:'AMD'}), (p1:Produit {id:'P1'})
MERGE (p)-[:APPARTIENT_A]->(c)
MERGE (p)-[:FABRIQUE_PAR]->(m)
MERGE (p1)-[r:SIMILAIRE_A]->(p) SET r.score=0.85
MERGE (p)-[s:SIMILAIRE_A]->(p1) SET s.score=0.85;

