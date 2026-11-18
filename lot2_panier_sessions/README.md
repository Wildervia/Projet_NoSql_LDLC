# Lot 2 — Panier et Sessions Utilisateurs (Redis)

## 1. Le besoin
LDLC reçoit des millions de visites par mois. Pour chaque visiteur, il faut gérer :
- une **session** : qui est le visiteur, est-il connecté, sur quelle page est-il ;
- un **panier** : quels produits il veut acheter, et en quelle quantité.

Contraintes du sujet :
- lecture et écriture **en moins d'1 milliseconde** ;
- paniers et sessions **volatils** : ils doivent **disparaître automatiquement** après une période d'inactivité ;
- les sessions doivent être **partagées entre plusieurs serveurs web** (le client peut passer d'un serveur à l'autre sans être déconnecté).

## 2. Le choix : Redis (base clé-valeur)

Redis fonctionne comme un grand casier à étiquettes : chaque **clé** (l'étiquette) donne directement accès à sa **valeur** (le contenu).

| Besoin | Réponse de Redis |
|---|---|
| Moins d'1 ms | Toutes les données sont **en mémoire vive (RAM)** : aucun accès disque, la réponse est quasi immédiate |
| Disparition automatique | Chaque clé peut avoir une **durée de vie (TTL)** : Redis la supprime tout seul à la fin |
| Partage entre serveurs | Redis est un **serveur central** : tous les serveurs web lisent et écrivent au même endroit |
| Accès simple | On connaît toujours la clé (`panier:U1`), donc pas besoin de recherche complexe |

**Pourquoi pas MongoDB ou une base SQL ?** Elles écrivent sur le disque et sont plus lentes. Elles proposent aussi des fonctions de recherche dont on n'a pas besoin ici.
**Pourquoi pas Cassandra ?** Elle est optimisée pour les gros volumes durables, pas pour des données de quelques minutes.

### Théorème CAP
Avec plusieurs serveurs Redis (réplication), la copie des données vers les serveurs secondaires se fait **en différé (asynchrone)**. Redis privilégie donc la **disponibilité et la rapidité (AP)** : en cas de panne, on peut perdre les toutes dernières modifications d'un panier.
C'est **acceptable** : un panier ou une session sont des données temporaires. Au pire, le client se reconnecte ou rajoute un produit. Les données importantes (commandes) ne sont pas stockées dans Redis.

## 3. Le modèle de données

### Règle de nommage des clés
`type:identifiant`, ce qui rend les clés lisibles et sans collision.

| Clé | Type Redis | Contenu | Durée de vie (TTL) |
|---|---|---|---|
| `session:abc123` | **HASH** | `user_id`, `nom`, `derniere_page` | **30 minutes** (1800 s) |
| `panier:U1` | **HASH** | un champ par produit : `P1 → 1`, `P3 → 2` | **7 jours** (604 800 s) |

### Exemple
```
session:abc123  →  { user_id: "U1", nom: "Jean", derniere_page: "/processeurs" }
panier:U1       →  { P1: "1", P3: "3" }
```

### Pourquoi un HASH ?
- Un **HASH** est une petite fiche avec des champs. On peut **lire ou modifier un seul champ** (un seul produit du panier) sans réécrire tout le panier.
- Avec une simple chaîne (`SET panier:U1 "{...json...}"`), il faudrait relire tout le panier, le modifier, puis le réécrire à chaque ajout de produit : c'est plus lent et risqué si deux actions arrivent en même temps.

### Pourquoi ces durées de vie ?
- **Session : 30 minutes.** Pour la **sécurité**, un client inactif est déconnecté.
- **Panier : 7 jours.** Pour le **confort**, un client qui revient quelques jours plus tard retrouve son panier.
- Le TTL est **relancé à chaque action** (`EXPIRE`) : la donnée disparaît après 30 minutes (ou 7 jours) **sans activité**, et non après 30 minutes au total.

### Lien avec les autres lots
- Le panier contient seulement les **identifiants des produits** (`P1`, `P3`…) du catalogue MongoDB (lot 1). Le **prix n'est pas stocké** dans le panier : il est toujours lu dans le catalogue, donc toujours à jour.
- Quand le client **valide sa commande**, le panier est enregistré dans **Cassandra** (lot 3, conservation longue durée), puis **supprimé** de Redis.

## 4. Commandes types
Toutes les commandes sont dans [`commandes.redis`](commandes.redis).

### Sessions
| Action | Commande |
|---|---|
| Créer une session | `HSET session:abc123 user_id U1 nom Jean derniere_page /accueil` |
| Lire la session | `HGETALL session:abc123` |
| Lire un seul champ | `HGET session:abc123 nom` |
| Fixer la durée de vie (30 min) | `EXPIRE session:abc123 1800` |
| Voir le temps restant | `TTL session:abc123` |
| Le client navigue (mise à jour + TTL relancé) | `HSET session:abc123 derniere_page /processeurs` puis `EXPIRE session:abc123 1800` |

### Panier
| Action | Commande |
|---|---|
| Ajouter des produits | `HSET panier:U1 P1 1 P3 2` |
| Afficher le panier | `HGETALL panier:U1` |
| Augmenter une quantité | `HINCRBY panier:U1 P3 1` |
| Retirer un produit | `HDEL panier:U1 P4` |
| Nombre de produits différents | `HLEN panier:U1` |
| Durée de vie (7 jours) | `EXPIRE panier:U1 604800` |
| Commande validée : supprimer le panier | `DEL panier:U1` |

### Test de l'expiration automatique
```
SET test:expiration bonjour EX 15    → clé créée avec 15 secondes de vie
GET test:expiration                  → "bonjour"
(15 secondes plus tard)
GET test:expiration                  → (nil)
EXISTS test:expiration               → 0   (Redis l'a supprimée tout seul)
```

## 5. Les compromis acceptés
- **La RAM coûte cher et est limitée.** On ne stocke dans Redis que des données **petites et temporaires**. Les TTL évitent que les paniers abandonnés remplissent la mémoire.
- **Risque de perte en cas de panne.** Redis peut sauvegarder sur disque (options RDB/AOF), mais une perte des toutes dernières secondes reste possible. C'est acceptable pour un panier, **pas pour une commande** : c'est pourquoi les commandes vont dans Cassandra.
- **Pas de recherche complexe.** On ne peut pas demander « tous les paniers contenant P1 ». Ce n'est pas un besoin ici : on accède toujours à un panier par sa clé.

## 6. Comment tester
1. Démarrer Redis avec Docker :
   ```
   docker run -d --name redis -p 6379:6379 redis
   ```
   (ou `docker start redis` s'il existe déjà)
2. Ouvrir la console Redis :
   ```
   docker exec -it redis redis-cli
   ```
3. Copier-coller les commandes de [`commandes.redis`](commandes.redis) une par une (les lignes commençant par `#` sont des commentaires).V