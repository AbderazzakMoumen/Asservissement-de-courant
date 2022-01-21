close all;
clear all;

%% Simulation

% PARAMETRES DANS SIMULINK
% Deux sch�mas Simulink sont utilis�s :
% - Moteur_Complet : (entr�e U, param�tre pente en �)
% - Moteur_Reduit : (entr�e I, param�tre pente en �)


% PARAMETRES DE SIMULATION � modifier � souhait
% Horizon de simulation en seconde
T_Sim=20;
% Masse totale de l'engin [kg]
M=85;


%% D�finition des param�tres m�ca de la trottinette, mod�lisation
Ts=T_Sim/200; % �chantillonnage (200 pts)
Fs=1/Ts;
% pesanteur [m.s-2]
g=9.81;
% rendement courroie []
n=1/0.8;
% Constante de couple [N.m/A]
KI=76e-3;
% Rayon Roue [m]
RRoue=0.1;
% Rayon pignon moteur [m]
R1=0.01;
% Rayon couronne roue [m]
R2=0.08;
% Inertie du rotor du moteur [kg.m2]
J1=1.23e-3; %0.5MR^2 (R=5cm)
% Inertie de la roue [kg.m2]
J2=0;
% frottement visqueux [N.m / (Rad/s) ]
fv=250e-6;

% Moment d'inertie total ramen� au moteur :
Jeq=J1+(1/n)*(R1/R2)^2*(J2+M*RRoue^2);
% Fct de transfert :             1/fv
%                    Omega(p) = -----------. KI*I(p) - C1(p)
%                               1 + p.J/fv
%C1 couple ramen� au rotor
% C1 = K_C1*pente(�)
K_C1 = RRoue*(R1/R2)*M*g*(pi/180)/n
Num_Meca = 1/fv;
Den_Meca = [Jeq/fv 1];
TF_Meca= tf(Num_Meca,Den_Meca);

%% D�finition des param�tres �lectrique de moteur, mod�lisation
% tension Batt [v]
E=24;
% r�sistance [Ohm]
R=1.2;
% inductance [H]
L=1.5e-3;
% constante de vitesse E=Kphi.Om�ga et I= Gamma/KI, Kphi=KI
Kphi=KI;

% Fct de transfert :             1/R
%                        I(p) = -----------. (U(p)- E(p))
%                               1 + p.L/R
%
Num_Elec = 1/R;
Den_Elec = [L/R 1];
TF_Elec= tf(Num_Elec,Den_Elec);


%% ======================================================================
% SIMU MOTEUR COMPLET
% =======================================================================
%% simu
sim('Moteur_Complet.mdl');


%% Approximation des grandeurs
% P=100W. U=24V N0 = 3000 tr/min = 3000*2*pi/60 rad/sec = 100pi = 314 rad/s
% KI = E0/N0 = 24/314 = 76e-3 N.m/A
% Frottement visqueux : � 314 rad /s (maxi), on oppose 75mN.m
% soit fv = 75e-3/314 = 238u

%% Affichage des scopes
subplot(2,1,1), plot(  Vitesse.time, Vitesse.signals.values)
subplot(2,1,2), plot(  Courant.time, Courant.signals.values)
subplot(2,1,1), title('Moteur Complet : Vitesse N [Tr/mn] en fonction du temps [s]')
subplot(2,1,2), title('MoteurComplet : Courant [A] en fonction du temps [s]')

%% ======================================================================
% SIMU MOTEUR PARTIEL (Uniquement la partie m�ca est simul�e)
% =======================================================================
%% simu
sim('Moteur_Partiel_Meca.mdl');
%% Affichage des scopes
figure;
subplot(2,1,1), plot(  Vitesse.time, Vitesse.signals.values)
subplot(2,1,1), title('Moteur partie m�ca seule : Vitesse N [Tr/mn] en fonction du temps [s]')



