glafoukHier à 10:28
@flew Bah pour les cubes, l'idée serait de reprendre l'effet du logo de .bin ... en gros une vue de dessus (un carré monocrhome) pis quand on lance le mouvement le carré devient 2 trapèzes collés (un de la couleur originale en bas + au dessus un bout d'une autre couleur qui fait la face) et le tout en mouvement progresssif... Et le jeu c'est de faire des "files" verticales de carrés comme ça qui traversent l'écran... Après j'ai pas idée vu qu'on est limité en sprite si c'est faisable ou si ça limite a 1 cube = 1 sprite, ce qui fait pas beaucoup quoi pour faire des serpents, vers, etc...
@flew Sinon y'a l'option serpent fait en lignes/petits trais, genre 2/4 couleurs pour avoir un peu plus de matière... Avec le truc de faire bouger la largeur des trais pour faire un effet de "il monte, il descend" (on peut aussi fader les lignes pour accentuer le rendu de profondeur, voir passer des bouts en noir pour faire genre il est passé sous terre). A priori un sprite faisant la hauteur qu'on veut, là on sait en faire bouger plusieurs en même temps...
@flew Et pour que les serpents aient des couleurs différentes, jouer sur "l'intercalage des lignes" (comme pour la font utilisée dans .bin) en faisait qu'un trais sur une ligne d'un serpent = du noir sur l'autre, et inversement la ligne suivante...
@flew Si le sprite fait 16px de large, on peut dire que la largeur d'base c'est 4, et ça laisse de quoi le faire onduler/tourner sur cette largeur totale...
@flew Tourner/onduler mais aussi "grossir/retrécir" en élargissant les trais...
MooZHier à 20:26
@p0ke ah chier, j'étais au resto hier
p0keHier à 21:10
@MooZ t'as raté la diffusion de lambo sur ma sms2
MooZHier à 21:11
!
glafoukAujourd’hui à 12:20
@flew Si ça peut t'motiver à replonger dans la VCS ... 1ère tune faite depuis un bon paquet d'temps, bon ça se sent hein héhéhé... (et alors pour caler des trucs qui bougent dessus, bon courage huhuhu)
867 octets, c'pas si pire...
Type de fichier joint : unknown
SnakeIt.ttt
85.54 KB
zerkmanAujourd’hui à 15:06
Cool j'ai corrigé les bugs d'affichage
flewAujourd’hui à 22:40
@glafouk cool, c'te zik. Y'a 2 melodies (une grave et une aigue) qui pourraient etre suivies par 2 serpents. Qui serpenteraient en fonction de la hauteur des notes, y'a p't'etre moyen d'essayer un truc. Ca m'parait complique pour pas grand chose l'histoire du cube, j'partirais plus sur l'option lignes/traits. j'vais reflechir
glafoukAujourd’hui à 22:41
@flew Mah si on sait faire un serpent de cubes, ça peut claquer (mais je doute que ça soit possible, y'a pas assez de sprites)
flewAujourd’hui à 22:42
Ben si les 2 serpents sont verticaux, on peut utiliser les 2 sprites sur toute la hauteur
glafoukAujourd’hui à 22:42
Ouais mais tu sais faire l'anim sur plusieurs endroits en même temps ?
flewAujourd’hui à 22:43
Mettons 8 cubes alignes verticalement qui bougent differemment ? ouai ca doit etre possibles
glafoukAujourd’hui à 22:44
Bah ça peut s'tenter alors... Avec des cubes de couleurs différentes selon les notes (mais v'là pour synch tout ça héhéhé)
flewAujourd’hui à 22:44
Ouai, s'ils font qq pixels de cote, on peut faire des animations en image par image
glafoukAujourd’hui à 22:45
En fait le top serait d'avoir les cubes ET les lignes, pour faire des fx différents et varier l'affaire...
flewAujourd’hui à 22:46
Ouaip, ca serait possible de varier avec les lignes
Pas con c't'histoire de couleur associee a la zik
P't'etre le mouvement aussi
glafoukAujourd’hui à 22:47
Bah avec les lignes, y'a les mouvement "haut/bas/disparait sous terre" avec la largeur + l'alpha de la couleur. Pis des mouvement droite/gauche d'ondulation.
Les cubes, on va les faire aller tout droit, c'va déjà être assez compliqué comme ça...
Pour les cubes, tu vois l'idée du mouvement 3d ?
flewAujourd’hui à 22:48
Ben pour le coup, on peut precalculer un beau mouvement 3d comme on veut avec un blender..
La grosse triche ; )
si je comprends ton idee a base du logo .bin, tu voudrais le faire tourner autour de l'axe horizontal
ca pourrait aussi etre une option.
glafoukAujourd’hui à 22:51
Ouais, juste avec 2 couleurs, une en plus pour faire le bout d'la face qui apparait...
Soit il est carré vu du dessus, soit c'est 2 trapèzes de 2 couleurs (celle de base + plus clair). Et ce mouvement peut marcher sur 2 sens.
flewAujourd’hui à 22:53
ouaip, j'suis pas sur qu'reconnaisse qu'il s'agit d'un cube qui tourne.
En fait l'idee de fausse 3d a laquelle je pensais est inspiree d'une demo CPC recente. Logon run je crois
Avec plein de petits cube qui volent partout
glafoukAujourd’hui à 22:54
Ah ouais, tu vise haut toi :slight_smile:
Quelle "finesse" de pixel on a, on est pas en mode 40x40 là si ?
flewAujourd’hui à 22:55
Ben c'est du precalcule, donc on devrait aussi pouvoir faire des petits cubes comme ca sur vcsc
Boh, si on utilise les sprites on a toute la resolution genre 160x240
glafoukAujourd’hui à 22:57
Ouais donc ça sera assez fin pour faire de belles anims comme le logo bin
flewAujourd’hui à 22:58
eu 160x192
ouaip, y'a moyen de faire des trucs fins
glafoukAujourd’hui à 22:59
Bah on va capter que c'est des cubes alors si c'est assez bien rendu la transformation.
flewAujourd’hui à 22:59
ouaip, j'ferai qq tests
glafoukAujourd’hui à 23:00
Bon par contre pour les couleurs ça va être chaud, si y'a une ligne de cubes + une ligne de lignes, elles seront d'la même couleur... Ou alors faut intercaler des lignes de vide sur les cubes, ça devient chaud...
T'crois que ça tiendrais en 4Ko ? :slight_smile:
flewAujourd’hui à 23:02
En fait on a 1 couleur par sprite, donc on peut avoir 2 couleurs differentes pour les 2 serpents
Une ligne de cubes avec ses couleurs, et une ligne de lignes avec ses couleurs independantes aussi
En 4K, j'dirais que ca peut tenir sans les cubes precalc
glafoukAujourd’hui à 23:03
Genre que en lignes ?
flewAujourd’hui à 23:03
Genre lignes et cubes a la .bin
c'est les cubes a la 'logon run' qui prendraient plus de place
glafoukAujourd’hui à 23:04
Ah Kay', bah c'cool, c'peut être chouette d'la 4Ko...
Mais à voir, les cubes précalc ça peut envoyer aussi :slight_smile:
flewAujourd’hui à 23:05
en fait, les cubes a la 'logon run' on pourrait pas avoir 1 couleur par face, du coup ca serait p't'etre moche
Ca pourrait aussi etre des ronds pleins
glafoukAujourd’hui à 23:07
Bah un FX avec plein de bidules qui font leur vie dans tous les sens, ça pourrait claquer ouais, cubes ou ronds...
flewAujourd’hui à 23:08
Et des carres qui tournent en 2d
glafoukAujourd’hui à 23:08
Aussi... Logon en fait ce qui claque, c'est l'accumulation
flewAujourd’hui à 23:09
ouai, bah sur vcs c'est plus complique d'en caser autant horizontalement, mais deja avec 2 lignes verticales, ca peut etre sympa
glafoukAujourd’hui à 23:10
J'avais pas pensé aux ronds, mais des serpents de ronds, avec des ronds qui grossissent/rapetissent + jeu sur l'alpha, ça peut aussi bien rendre...
flewAujourd’hui à 23:11
ouaip
glafoukAujourd’hui à 23:13
Bon on a le "concept", maintenant faut voir s'il est "prouf"
flewAujourd’hui à 23:13
prouf ?
glafoukAujourd’hui à 23:14
Bah, le fameux "proufofeconcept"
flewAujourd’hui à 23:14
; )
yes, va falloir que j'me motive
glafoukAujourd’hui à 23:15
Pour la zik faudrait que j'fasse un truc avec des mélodies plus "claires" et moins entremélées.... et avec un coté plus détaché/indentifiable...
On verra...
flewAujourd’hui à 23:17
On pourrait meme imaginer 3 serpents
en fait meme 4
glafoukAujourd’hui à 23:18
Bah un qui serait les drums... Et un la "mélodie secondaire qui bouche les trous" (ce qui revient à une note tous les j'sais pas combien)
flewAujourd’hui à 23:18
2 en sprites avec les formes qu'on veut, 1 en missile et 1 en 'ball' qui serait des serpents en lignes
glafoukAujourd’hui à 23:18
L'idée aussi serait d'avoir les serpent en "morceaux", et chaque bout c'est une note... Mais bon, c'va pas être sumple
flewAujourd’hui à 23:18
bon, p't'etre que ca va bouger qd j'vais m'rendre compte que c'est pas possible
glafoukAujourd’hui à 23:19
Huhuhu...
flewAujourd’hui à 23:19
yes .. donc a priori la largeur des sprites ca serait 8, pas 16 ; )
mais on peut les faire bouger librement de gauche a droite
glafoukAujourd’hui à 23:20
Et on peut aussi jouer sur le background aussi, et jouer avec la couleur pour faire comme si le sol évoluait en matière et en hauteur avec l'alpha
Vu que ça défile...
flewAujourd’hui à 23:20
ouaip, c'pas con.
bon je sens deja que finalement si on arrive a fire 2 serpents ca sera pas mal ; )
glafoukAujourd’hui à 23:23
Bah le missile et la ball, ils sont chiant à gérer ? Pasque pour la drum (qui en général est le snare) ça serait marrant, genre un élément qui défile quasi à cadence régulière (sauf quand y'a les breaks)
Un bête trais... Mais qui passerait vite, et qui serait pas toujours au même endroit niveau latéral...
flewAujourd’hui à 23:24
P't'etre pas si reloud qu'ca, faut que je vois s'ils ont des couleurs independantes
glafoukAujourd’hui à 23:24
Bah c'pas si dérangement s'il prend la même couleur que les sprites... Vu qu'il va aller vachement plus vite, genre un snare = une traversée d'écran
flewAujourd’hui à 23:26
ouai ca peut le faire, a voir le rendu
ah, on peut avoir 3 couleurs distinctes + le background
glafoukAujourd’hui à 23:30
Bah par ligne, ça l'fait...
flewAujourd’hui à 23:30
c'est ca
glafoukAujourd’hui à 23:31
ça fait 3 objets quoi...
flewAujourd’hui à 23:32
yes, 3 objets (dont un en lignes) + le background qui pourrait changer de couleur d'une ligne a l'autre
glafoukAujourd’hui à 23:32
Bah avec des dégradés en alpha, ça peut rendre pas mal le coté le sol change...
flewAujourd’hui à 23:32
yes

glafoukAujourd’hui à 23:34
On peut même imaginer avec les sprites, des formes "reconnaissables", des coeurs, des invaders, mais heu seront à plat et ne pourront se dandiner que sur l'horiz...
flewAujourd’hui à 23:35
ouaip
glafoukAujourd’hui à 23:35
Le mix forme statiques qui défilent + objets mouvants (cubes, lignes) ça peut rendre sympa
flewAujourd’hui à 23:36
pourquoi tu placerais les lignes dans les objets mouvants ?
Apres, on peut meme faire des petits invaders animes ..
glafoukAujourd’hui à 23:38
Bah elles peuvent varier en largeur, en horiz et en alpha, donc c'est un objet qui bouge comparé à un bête sprite qui va défiler juste en vertical
Ah oui, genre en anim image/image
Mais c'est chaud à caler si sur une fournée, y'en a 6 qui se suivent...
flewAujourd’hui à 23:39
Ben les sprites on peut les faire vairier pareil: lageur (x1, x2, x4), horizontal, alpha et couleur
glafoukAujourd’hui à 23:40
Ouais mais... une "ligne" d'objet sprite, c'est le même sprite sur toute la hauteur composé de pleins d'éléments... Donc tout bouge pareil ensemble non ?
flewAujourd’hui à 23:40
Et on devrait pouvoir caler une fournee de sprites qui se suivent
on peut changer le contenu du sprite a chaque ligne
glafoukAujourd’hui à 23:40
Ah kay, donc on peut "faire ce qu'on veux" en fait :slight_smile:
flewAujourd’hui à 23:41
Et on peut changer la position du sprite d'une ligne a l'autre
ouai c'est ca
faut faire le prouf mais la comme ca ca m'a l'air a peu pres jouable
glafoukAujourd’hui à 23:42
Bah c'cool, ça fait pleins de bidules différents, si on varie le rythme des fournées avec le son, les couleurs, pis les éléments, ça devrait rendre bien dense et dynamique
flewAujourd’hui à 23:43
ouai, ca peut rendre sympa
apres faut voir comment on raccroche les elements graphiques avec le son
glafoukAujourd’hui à 23:43
Bah faudra penser la zik exprès pour ça (là ce que j'ai fait ce matin, c'tait au pif)
Le souci, c'est qu'avec 2 pistes, c'pas évident de faire des "couches superposées" comme dans isometic
flewAujourd’hui à 23:45
ben deja avec 2 lignes de melodies et un drum, on devrait avoir les mouvements de nos 2 serpents et de la balle
a voir si on peut utiliser directement la data de la zik ou si faut faire un 'script' qui colle a la zik
genre hauteur de note et volume de note
qui pourraient etre lies a l'amplitude d'oscillation horizontale et 'scaling'
apres comme y'a 2 canaux, c'est p't'etre pas evident d'identifier quand c'est une note ou un drum.
j'regarderai a quoi on a acces comme info du player de zik
glafoukAujourd’hui à 23:50
Ouais ça doit être un beau merdier entremélée... Mais bon, dans TIatracker, les drums semblent "bien identifiées" pas pareil, donc peut être que dans l'code ça se vois easy
flewAujourd’hui à 23:50
j'regarde
ouai, l'info de l'instrument est accessible easy en memoire
glafoukAujourd’hui à 23:56
Cool...
