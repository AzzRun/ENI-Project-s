USE LOCATIONS;
go

-- 1.   Liste des clients (nom, pr�nom, adresse, code postal, ville) ayant au moins une fiche de
--      location en cours.
SELECT DISTINCT nom, 
        prenom , 
        adresse, 
        cpo , 
        ville
FROM    clients c JOIN fiches f ON (c.noCli = f.noCli)
WHERE   etat = 'EC';

SELECT  nom, 
        prenom , 
        adresse, 
        cpo , 
        ville
FROM    clients c JOIN fiches f ON (c.noCli = f.noCli)
WHERE   etat = 'EC'
GROUP BY c.nocli, 
        nom, 
        prenom, 
        adresse, 
        cpo, 
        ville;

-- 2.   D�tails de la fiche de location de M. Dupond Jean de Paris (avec la d�signation des articles
--      lou�s, la date de d�part et de retour)
SELECT  f.noFic 'n� fiche', 
        designation, 
        CONVERT(VARCHAR,depart, 103) , 
        ISNULL(CONVERT(VARCHAR,retour, 103), '-') retour
FROM    clients c   JOIN fiches f ON (c.noCli = f.noCli)
                    JOIN lignesFic l ON (f.noFic = l.noFic)
                    JOIN articles a ON (l.refart = a.refart)
WHERE   nom = 'Dupond' 
AND     prenom = 'Jean' 
AND     ville = 'Paris';

-- 3.   Afficher tous les articles (r�f�rence, d�signation et libell� de la cat�gorie) dont le libell� de la cat�gorie contient ski.
SELECT  refart, 
        designation, 
        libelle
FROM    articles a  JOIN categories c ON (a.codeCate = c.codeCate)
WHERE   libelle LIKE '%ski%';

-- 4.   Calcul du montant de chaque fiche sold�e et du montant total des fiches.
-- VRSION TABLES TEMPORAIRES (SQLSERVER)

drop table #TotalFichesSoldees;
SELECT  SUM((DATEDIFF(DAY, depart, retour)+1)*PrixJour) total
INTO #TotalFichesSoldees
FROM    fiches f JOIN lignesFic l ON (f.noFic = l.noFic)
                 JOIN articles a ON (l.refart = a.refart)
                 JOIN grilleTarifs g ON (a.codeCate = g.codeCate 
                                    AND a.codeGam = g.codeGam)
                 JOIN tarifs t ON (g.codeTarif = t.codeTarif)
WHERE   etat = 'SO';

drop table #FichesSoldees;
SELECT  f.noFic , 
        SUM((DATEDIFF(DAY, depart, retour)+1)*PrixJour) total
INTO #FichesSoldees
FROM    fiches f JOIN lignesFic l ON (f.noFic = l.noFic)
                 JOIN articles a ON (l.refart = a.refart)
                 JOIN grilleTarifs g ON (a.codeCate = g.codeCate 
                                    AND a.codeGam = g.codeGam)
                 JOIN tarifs t ON (g.codeTarif = t.codeTarif)
WHERE   etat = 'SO'
GROUP BY f.noFic;

SELECT  * 
FROM    #FichesSoldees CROSS JOIN #TotalFichesSoldees;

-- VERSION SOUS-REQUETES
SELECT  *
FROM    (SELECT  SUM((DATEDIFF(DAY, depart, retour)+1)*PrixJour) total
        FROM    fiches f JOIN lignesFic l ON (f.noFic = l.noFic)
                         JOIN articles a ON (l.refart = a.refart)
                         JOIN grilleTarifs g ON (a.codeCate = g.codeCate 
                                            AND a.codeGam = g.codeGam)
                         JOIN tarifs t ON (g.codeTarif = t.codeTarif)
        WHERE   etat = 'SO') SR1 CROSS JOIN (  SELECT  f.noFic , 
                                                        SUM((DATEDIFF(DAY, depart, retour)+1)*PrixJour) total
                                                FROM    fiches f JOIN lignesFic l ON (f.noFic = l.noFic)
                                                                 JOIN articles a ON (l.refart = a.refart)
                                                                 JOIN grilleTarifs g ON (a.codeCate = g.codeCate 
                                                                                    AND a.codeGam = g.codeGam)
                                                                 JOIN tarifs t ON (g.codeTarif = t.codeTarif)
                                                WHERE   etat = 'SO'
                                                GROUP BY f.noFic) SR2;



-- 5.   Calcul du nombre d�articles actuellement en cours de location.
SELECT  COUNT(*) 'nombre d''articles en cours de location'
FROM    lignesFic JOIN fiches on (lignesFic.noFic = fiches.noFic)
WHERE   retour IS NULL 
and     etat='EC';

-- 6.   Nombre d�articles lou�s par client.
SELECT  nom, 
        prenom, 
        COUNT(*) AS 'nombre de location effectu�es'
FROM    clients c JOIN fiches f ON (c.noCli = f.noCli)
                  JOIN lignesFic l ON f.noFic = l.noFic
GROUP BY c.noCli, 
        nom, 
        prenom;

-- 7.   Affichage des clients qui ont effectu� (ou sont en train d�effectuer) plus de 200� de location.
SELECT  nom, 
        prenom, 
        SUM((DATEDIFF(DAY, depart, ISNULL(retour, GETDATE()))+1)*prixJour) total
FROM    clients c JOIN fiches f ON (c.noCli = f.noCli)
                  JOIN lignesFic l ON (f.noFic = l.noFic)
                  JOIN articles a ON (l.refart = a.refart)
                  JOIN grilleTarifs g ON (a.codeCate = g.codeCate 
                                        AND a.codeGam = g.codeGam)
                  JOIN tarifs t ON (g.codeTarif = t.codeTarif)
GROUP BY c.noCli, 
        nom, 
        prenom
HAVING SUM((DATEDIFF(DAY, depart, ISNULL(retour, GETDATE()))+1)*prixJour) >= 200;

-- 8.   Liste des articles lou�s et le nombre de fois qu�ils ont �t� lou�s.
SELECT  l.refart, 
        designation, 
        COUNT(*)
FROM    lignesFic l JOIN articles a ON (l.refart = a.refart)
GROUP BY l.refart, 
        designation
ORDER BY 3 DESC;

--garder les articles non lou�s (jointure externe de articles vers lignesfic)
select  a.refart, 
        designation, 
        g.libelle, 
        c.libelle, 
        COUNT(l.refart)
 from articles a JOIN gammes g on (a.codeGam = g.codeGam)
                 JOIN categories c on a.codeCate = c.codeCate
                 left join lignesFic l on (a.refart = l.refart)
 group by a.refart, 
        designation, 
        g.libelle, 
        c.libelle;
        

-- 9.   Liste des fiches (n�, nom, pr�nom) de moins de 150�
SELECT  f.nofic, 
        nom, 
        prenom, 
        SUM((DATEDIFF(DAY, depart, ISNULL(retour, GETDATE()))+1)*prixJour)
FROM    clients c JOIN fiches f ON (c.noCli = f.noCli)
                  JOIN lignesFic l ON (f.noFic = l.noFic)
                  JOIN articles a ON (l.refart = a.refart)
                  JOIN grilleTarifs g ON (a.codeCate = g.codeCate 
                                        AND a.codeGam = g.codeGam)
                  JOIN tarifs t ON (g.codeTarif = t.codeTarif)
GROUP BY f.noFic, 
        nom, 
        prenom
HAVING SUM((DATEDIFF(DAY, depart, ISNULL(retour, GETDATE()))+1)*prixJour)< 150;

-- 10.  Moyenne des recettes de 'SURF'
SELECT  AVG((DATEDIFF(DAY, depart, ISNULL(retour, GETDATE()))+1)*prixJour)
FROM    lignesFic l JOIN articles a ON (l.refart = a.refart)
                    JOIN grilleTarifs g ON (a.codeCate = g.codeCate AND a.codeGam = g.codeGam)
                    JOIN tarifs t ON (g.codeTarif = t.codeTarif)
WHERE a.codeCate = 'SURF';

-- 11.  Dur�e moyenne d'une location d'une paire de ski (en journ�es enti�res).
SELECT  AVG((DATEDIFF(DAY, depart, ISNULL(retour, GETDATE()))+1))
FROM    lignesFic l JOIN articles a ON (l.refart = a.refart)
                    JOIN grilleTarifs g ON (a.codeCate = g.codeCate AND a.codeGam = g.codeGam)
                    JOIN tarifs t ON (g.codeTarif = t.codeTarif)
WHERE a.codeCate = 'SA';