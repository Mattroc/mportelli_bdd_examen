-- EXAMEN SQL (Matthieu Portelli)

-- A -- Créer la base de données « examen » en UTF 8
create database examen default CHARSET=utf8mb4 collate utf8mb4_unicode_ci;

-- B -- Charger ces 3 fichiers sql : commande_ligne.sql , client.sql et commande.sql dans la base « examen »
mysql -u root -h localhost -D examen < C:\Users\HB\Desktop\commande_ligne.sql

mysql -u root -h localhost -D examen < C:\Users\HB\Desktop\client.sql

mysql -u root -h localhost -D examen < C:\Users\HB\Desktop\commande.sql



-- 1 -- Afficher tous les détails de tous les clients
select * from client;



-- 2 -- Afficher sans redondance la liste des noms des produits qui ont déjà été commandés

/* Avec 'distinct j'évite les redondances, je rajoute une commande 'where' pour être certain que les produits affichés ont été commandés au moins une fois */
select distinct nom from commande_ligne where quantite > 0;



-- 3 -- Afficher la liste des noms des produits listés dans la commande numéro 10

/* Avec 'where' je cible spécifiquement la commande ayant pour id 10 */
select commande_id, nom from commande_ligne where commande_id = 10;



-- 4 -- Afficher la liste des noms des produits listés dans la commande numéro 10 ainsi que le nom du client et la date de commande

/* Jointure des 3 tables afin de récupérer toutes les informations demandées */
select client.prenom, client.nom, commande_ligne.commande_id, commande_ligne.nom, commande.date_achat
from commande
left join commande_ligne on commande_ligne.commande_id = commande.id
left join client on client.id = commande.client_id
where commande_ligne.commande_id = 10;



-- 5 -- Afficher le montant total de la commande numéro 10

/* Pour récupérer le montant total d'une commande je dois d'abord multiplier la quantité d'un produit avec son prix à l'unité, puis faire la somme des différents produits de la commande */
select sum(quantite * prix_unitaire) as montant_total_commande_10
from commande_ligne
where commande_id = 10;



-- 6 -- Afficher la liste des commandes (id, date_achat ) avec la somme totale de chaque commande (1 ligne par commande)

/* En utilisant le calcul de la question précédente je fais une jointure avec la table commande pour récupérer les dates d'achat et j'affiche mes résultats grâce au 'group by' afin d'avoir les totaux par commande */
select commande_ligne.commande_id, commande.date_achat, sum(commande_ligne.quantite * commande_ligne.prix_unitaire) as montant_total_commande
from commande_ligne
left join commande on commande.id = commande_ligne.commande_id
group by commande.id;



-- 7 -- Quel est le client qui a le plus gros chiffre d’affaires

/* Je fais la jointure entre les 3 tables afin de récupérer le nom et prénom du client qui est associé à plusieurs commandes, elles-mêmes contenant plusieurs produits, j'utilise donc à nouveau les éléments des questions précédentes afin d'obtenir le montant total par client, j'ordonne ma liste du plus grand montant au plus petit et je limite l'affichage au premier de cette liste  */
select client.prenom, client.nom, sum(commande_ligne.quantite * commande_ligne.prix_unitaire) as montant_total_commande
from commande
left join commande_ligne on commande_ligne.commande_id = commande.id
left join client on client.id = commande.client_id
group by commande.client_id
order by montant_total_commande desc
limit 1;



-- 14 -- Supprimer tous les clients qui habitent à Marseille

/* Avec le 'where' je cible ceux habitant à 'Marseille' */
delete from client
where client.ville = 'Marseille';



-- 15 -- Que fait la requête suivante ? Exécutez la.

/* Le 'alter table' me permets d'altérer une table existante et dans ce cas précis de rajouter une colonne ayant pour titre 'code_postal', je spécifie également le type de données de la colonne comme étant des chaînes de caractère au nombre maximum de 5 et cela étant 'null' par défaut */
alter table client add code_postal varchar(5) null;



-- 16 -- Mettre à jour le code postal de tous les clients de « Saint Etienne » avec la valeur « 42000 »

/* Avec 'update' je peux modifier les valeurs dans une table, je spécifie où avec le 'where' dans mon cas les clients ayant pour ville Saint-Etienne */
update client
SET code_postal = '42000'
WHERE client.ville = 'Saint-Etienne';



-- 17 -- Créer la procédure stockée qui affiche tous les noms de clients. Exécuter là.

/* Je remplis ma procédure stockée avec une requête qui récupère les noms et prénoms des clients */
delimiter //
create procedure afficher_nom_client()
begin
    select client.prenom, client.nom
    from client;
end //
delimiter ;

/* J'appelle ma procédure stockée */
call afficher_nom_client();



-- 18 -- Qu’essaie de faire le trigger suivant (soyez très précis). Quelle est l’erreur présente dans ce trigger ?

/* Version de l'énoncé */
delimiter |
create trigger mise_a_jour_client
before delete on client
    delete from commande_ligne
    where commande_id IN (select id from commande where client_id = old.id);
    delete from commande
    where client_id = new.id;
begin
end
delimiter ;

/* Ma version : j'ai rajouté 'for each row' après avoir déclaré ma table 'client', j'ai mis le 'begin' à la bonne place (avant le bloc d'instructons), j'ai remplacé le 'new.id' par 'old.id' (jamais de NEW dans un DELETE) et j'ai rajouté '|' après le 'end' pour équilibrer avec le '|' de la première ligne */
delimiter |
create trigger mise_a_jour_client
before delete on client
for each row
begin
    delete from commande_ligne
    where commande_id IN (select id from commande where client_id = old.id);
    delete from commande
    where client_id = old.id;
end |
delimiter ;

/* Description du trigger :
- je le crée en le nommant 'mise_a_jour_client'
- il agira AVANT d'effacer des informations sur la table 'client'
- pour chaque ligne
- il commence le bloc des deux instructions avec le 'begin'
- il devra effacer sur la table 'commande_ligne' les informations liées au client effacé donc les produits que contenaient sa ou ses commandes (via son 'client_id' et sa 'commande_id')
- il devra effacer sur la table 'commande' la ligne concernant le client effacé (via son 'client_id') donc sa commande
- le 'end' boucle le bloc d'instructions
- je redéfinis le delimiter de mes instructions en ';'
 */

--  FIN