# Lot 4 — Recommandations produits (Neo4j)

## Problématique
Identifier les relations entre les produits LDLC pour proposer des recommandations pertinentes : produits compatibles, similaires ou fréquemment achetés ensemble.

## Choix technique
Neo4j, base NoSQL orientée graphe, permet de représenter et parcourir efficacement les relations entre produits avec Cypher. Il complète MongoDB (catalogue), Redis (panier et sessions) et Cassandra (logs et analytics).

## Modèle de données
- Nœuds : `Produit` (`id`, `nom`, `prix`, `stock`), `Categorie` (`nom`), `Marque` (`nom`).
- Relations : `COMPATIBLE_AVEC`, `SIMILAIRE_A` (`score`), `ACHETE_AVEC` (`nombre_achats`), `APPARTIENT_A`, `FABRIQUE_PAR`.
- Les identifiants `P1` à `P5` correspondent à ceux du Lot 1 MongoDB.

## Fichiers
- `recommandations.cypher` : contraintes, données d'exemple, relations et visualisation du graphe.
- `requetes.cypher` : onze requêtes et démonstrations de recommandation.

## Exécution
1. Démarrer une base Neo4j locale ou une instance Neo4j AuraDB de test.
2. Ouvrir Neo4j Browser et sélectionner la base de test.
3. Exécuter les instructions de `recommandations.cypher` dans l'ordre. Si le Browser n'accepte pas plusieurs instructions à la fois, les exécuter une par une.
4. Exécuter les requêtes de `requetes.cypher` séparément (R1 à R10).
5. Pour tester `SIMILAIRE_A`, exécuter R11, puis relancer R4.

## Résultats attendus (avant R11)
- 5 nœuds Produit, 5 Categorie, 5 Marque, soit 15 nœuds.
- 5 relations APPARTIENT_A, 5 FABRIQUE_PAR, 6 COMPATIBLE_AVEC et 8 ACHETE_AVEC, soit 24 relations dirigées.
- R2 : P2 et P3 ; R3 : P2 (18 achats), P3 (12 achats) ; R4 : aucun résultat tant que R11 n'a pas été exécutée.

## Intégration avec les autres lots
Dans une application complète, les produits sont synchronisés depuis MongoDB vers Neo4j en conservant leur identifiant. Les co-achats peuvent être calculés à partir des commandes enregistrées dans Cassandra puis injectés dans les relations `ACHETE_AVEC`. Le panier Redis peut servir à choisir le produit de départ pour une recommandation. **Cette synchronisation n'est pas implémentée ici** : le lot fournit un prototype Cypher autonome.

## Limites et précautions
- Les fréquences d'achats groupés et le score de similarité de R11 sont **des données fictives de démonstration**.
- Une relation `COMPATIBLE_AVEC` ne remplace pas une validation complète des contraintes techniques (BIOS, boîtier, alimentation, etc.).
- Les relations réciproques sont stockées dans les deux sens pour simplifier les requêtes ; les comptes de relations les incluent toutes les deux.
- Ne pas exécuter ces exemples sur une base de production sans vérification.
