-- ===== Lot 3 - Logs et Analytics (Cassandra) =====


CREATE KEYSPACE IF NOT EXISTS ldlc_analytics
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};


USE ldlc_analytics;

-- ===== Question 1 : combien de vues pour ce produit aujourd'hui ? =====

CREATE TABLE IF NOT EXISTS vues_par_produit_jour (
  produit_id text,
  jour       date,
  heure_vue  timestamp,
  user_id    text,
  page       text,
  PRIMARY KEY ((produit_id, jour), heure_vue, user_id)
) WITH CLUSTERING ORDER BY (heure_vue DESC, user_id ASC);

-- Quelques vues de test (chaque clic sur une fiche produit = 1 ligne)
INSERT INTO vues_par_produit_jour (produit_id, jour, heure_vue, user_id, page) VALUES ('P1', '2026-11-18', '2026-11-18 09:15:00', 'U1', '/produit/P1');
INSERT INTO vues_par_produit_jour (produit_id, jour, heure_vue, user_id, page) VALUES ('P1', '2026-11-18', '2026-11-18 10:02:00', 'U2', '/produit/P1');
INSERT INTO vues_par_produit_jour (produit_id, jour, heure_vue, user_id, page) VALUES ('P1', '2026-11-18', '2026-11-18 14:40:00', 'U3', '/produit/P1');
INSERT INTO vues_par_produit_jour (produit_id, jour, heure_vue, user_id, page) VALUES ('P1', '2026-11-17', '2026-11-17 18:20:00', 'U1', '/produit/P1');
INSERT INTO vues_par_produit_jour (produit_id, jour, heure_vue, user_id, page) VALUES ('P4', '2026-11-18', '2026-11-18 11:30:00', 'U2', '/produit/P4');

-- La réponse à la question
SELECT COUNT(*) FROM vues_par_produit_jour WHERE produit_id = 'P1' AND jour = '2026-11-18';

-- Voir le détail des vues, de la plus récente à la plus ancienne
SELECT heure_vue, user_id FROM vues_par_produit_jour WHERE produit_id = 'P1' AND jour = '2026-11-18';


-- ===== Question 2 : top des produits consultés cette semaine =====

-- Table A : un compteur par produit et par semaine
CREATE TABLE IF NOT EXISTS vues_par_semaine (
  semaine    text,
  produit_id text,
  nb_vues    counter,
  PRIMARY KEY ((semaine), produit_id)
);

-- À chaque vue, on ajoute +1 (ici, on simule plusieurs vues d'un coup)
UPDATE vues_par_semaine SET nb_vues = nb_vues + 120 WHERE semaine = '2026-S47' AND produit_id = 'P1';
UPDATE vues_par_semaine SET nb_vues = nb_vues + 45  WHERE semaine = '2026-S47' AND produit_id = 'P2';
UPDATE vues_par_semaine SET nb_vues = nb_vues + 80  WHERE semaine = '2026-S47' AND produit_id = 'P3';
UPDATE vues_par_semaine SET nb_vues = nb_vues + 200 WHERE semaine = '2026-S47' AND produit_id = 'P4';
UPDATE vues_par_semaine SET nb_vues = nb_vues + 10  WHERE semaine = '2026-S47' AND produit_id = 'P5';

-- Voir les compteurs : ils sont rangés par produit_id, PAS par nombre de vues
SELECT * FROM vues_par_semaine WHERE semaine = '2026-S47';

-- Table B : le classement, déjà trié (rempli chaque nuit à partir de la table A)
CREATE TABLE IF NOT EXISTS top_produits_semaine (
  semaine    text,
  nb_vues    bigint,
  produit_id text,
  nom        text,
  PRIMARY KEY ((semaine), nb_vues, produit_id)
) WITH CLUSTERING ORDER BY (nb_vues DESC, produit_id ASC);

INSERT INTO top_produits_semaine (semaine, nb_vues, produit_id, nom) VALUES ('2026-S47', 200, 'P4', 'Logitech G PRO X SUPERLIGHT 2');
INSERT INTO top_produits_semaine (semaine, nb_vues, produit_id, nom) VALUES ('2026-S47', 120, 'P1', 'AMD Ryzen 7 7800X3D');
INSERT INTO top_produits_semaine (semaine, nb_vues, produit_id, nom) VALUES ('2026-S47', 80,  'P3', 'Corsair Vengeance DDR5 32 Go');
INSERT INTO top_produits_semaine (semaine, nb_vues, produit_id, nom) VALUES ('2026-S47', 45,  'P2', 'MSI MAG B650 TOMAHAWK WIFI');
INSERT INTO top_produits_semaine (semaine, nb_vues, produit_id, nom) VALUES ('2026-S47', 10,  'P5', 'Microsoft Windows 11 Famille');

-- La réponse à la question : le top 3 de la semaine
SELECT produit_id, nom, nb_vues FROM top_produits_semaine WHERE semaine = '2026-S47' LIMIT 3;


-- ===== Question 3 : historique des commandes d'un client =====

CREATE TABLE IF NOT EXISTS commandes_par_client (
  client_id     text,
  date_commande timestamp,
  commande_id   text,
  produits      map<text, int>,
  total         decimal,
  statut        text,
  PRIMARY KEY ((client_id), date_commande, commande_id)
) WITH CLUSTERING ORDER BY (date_commande DESC, commande_id ASC);

-- La commande de Jean (U1) : c'est son panier Redis validé (P1 x1, P3 x3)
INSERT INTO commandes_par_client (client_id, date_commande, commande_id, produits, total, statut)
VALUES ('U1', '2026-11-18 16:30:00', 'C003', {'P1': 1, 'P3': 3}, 719.80, 'payée');

-- Ses commandes précédentes
INSERT INTO commandes_par_client (client_id, date_commande, commande_id, produits, total, statut)
VALUES ('U1', '2026-10-05 11:12:00', 'C002', {'P4': 1}, 159.95, 'livrée');

INSERT INTO commandes_par_client (client_id, date_commande, commande_id, produits, total, statut)
VALUES ('U1', '2026-06-21 20:45:00', 'C001', {'P5': 1}, 145.00, 'livrée');

-- Une commande d'un autre client
INSERT INTO commandes_par_client (client_id, date_commande, commande_id, produits, total, statut)
VALUES ('U2', '2026-11-10 09:00:00', 'C004', {'P2': 1}, 219.95, 'expédiée');

-- La réponse à la question : l'historique de Jean, du plus récent au plus ancien
SELECT date_commande, commande_id, produits, total, statut FROM commandes_par_client WHERE client_id = 'U1';

-- Variante : les commandes de Jean depuis le 1er octobre
SELECT date_commande, commande_id, total FROM commandes_par_client WHERE client_id = 'U1' AND date_commande >= '2026-10-01';

-- ===== Conservation : les logs de vues sont supprimés automatiquement après 1 an =====
ALTER TABLE vues_par_produit_jour WITH default_time_to_live = 31536000;
