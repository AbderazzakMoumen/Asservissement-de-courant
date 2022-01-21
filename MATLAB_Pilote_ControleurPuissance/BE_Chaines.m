
%      ASSERVISSEMENT EN COURANT DE LA TROTINETTE %


clear all;
close all;
clc;

%% Simulation
T_Sim=3E-3;
T_s= T_Sim/1000;


%% Declaration CONSTANTES 

%Pour G_Elec(p)
U_bat = 24;
L = 2E-3;
R = 1;
K0 = 1/R;
T0 = L/R;
G0 = 2*U_bat*K0;

%Pour G_Meca(p)

g=9.81; % pesanteur [m.s-2]

n=1/0.8; % rendement courroie []

KI=76e-3; % Constante de couple [N.m/A]

RRoue=0.1; % Rayon Roue [m]
R1=0.01; % Rayon pignon moteur [m]

R2=0.08;% Rayon couronne roue [m]

J1=1.23e-3; % Inertie du rotor du moteur [kg.m2] %0.5MR^2 (R=5cm)
J2=0; % Inertie de la roue [kg.m2]

fv=250e-6; % frottement visqueux [N.m / (Rad/s) ]


M=85; % Masse totale de l'engin [kg]

Jeq=J1+(1/n)*(R1/R2)^2*(J2+M*RRoue^2); % Moment d'inertie total ramené au moteur :

% Fct de transfert :             1/fv
%                    Omega(p) = -----------. KI*I(p) - C1(p)
%                               1 + p.J/fv
%C1 couple ramené au rotor
% C1 = K_C1*pente(°)
K_C1 = RRoue*(R1/R2)*M*g*(pi/180)/n;


%Pour T(p)
Si = 0.1041;  % capteur courant
R5 = 5.1E3;
R8 = 10E3;
R12 = 10E3;
R18 = 12E3;
R21 = 220;
C2 = 22E-9;
C7 = 22E-9;
Kmef = ((R18/R12)+1)*(R8/(R5+R8)); % pour le filtre
T1 = ((R5*R8)/(R5+R8))*C2;
T2 = R21*C7;
G1 = Kmef*Si;
Kretour = G1;


%Pour C(p)
ft = 400;  %frequence de transition souhzité egale à 400Hz
f4 = ft/(G0*G1);
T3 = T0; %Pour compenser celui du moteur qui est le pole dominant (pole lent)
T4 = 1/(2*pi*f4);

% Valeur de consigne de l'échelon de courant
I0=1;



%% Modélisation électrique du moteur
Num_Elec = G0;
Den_Elec = [T0 1];
G_Elec =tf(Num_Elec,Den_Elec);

%% Modélisation mécanique du moteur
Num_Meca = 1/fv;
Den_Meca = [Jeq/fv 1];
G_Meca= tf(Num_Meca,Den_Meca);

%% Modélisation de F(p)
Num_F = Kmef*Si;
Den_F = [T1*T2 T1+T2 1];
F =tf(Num_F,Den_F);

%% Modélisation de C(p)
Num_C = [T3 1];
Den_C = [T4 0];
C =tf(Num_C,Den_C)

%% Modélisation de C(Z)(passage au correcteur numerique)
figure(2)
fe = ft*10; %Période d’échantillonnage
Te = 1/fe
% Fct de transfert :          a1*z + a0
%                    C(z) = -----------
%                             b1*z + b0

a1 = Te+2*T3
a0 = Te-2*T3
b1 = 2*T4
b0 = -2*T4

%% Lancer la simulation
sim('Moteur_Complet.mdl');
%% Affichage des scopes pour C(p)
figure(1)
subplot(2,1,1), plot(Vretour.time,Vretour.signals.values)
hold on
plot(Vconsigne.time, Vconsigne.signals.values)
hold off
legend('Vretour_I','Vconsigne_I')
subplot(2,1,2), plot(Iref.time, Iref.signals.values)
hold on
plot(I.time,I.signals.values)
hold off
legend('Iref)','I')

%% %% Affichage des scopes pour C(z)
figure(2)
subplot(2,1,1), plot(Vretour1.time,Vretour1.signals.values)
hold on
plot(Vconsigne1.time, Vconsigne1.signals.values)
hold off
legend('Vretour_I1','Vconsigne_I1')
subplot(2,1,2), plot(Iref1.time, Iref1.signals.values)
hold on
plot(I1.time,I1.signals.values)
hold off
legend('Iref1','I1')

%% Test marge de phase >= 45°
figure(3)
C1 =tf(Num_C,Den_C,'InputDelay',Te/2)
HBO = C1*G_Elec*F
margin(HBO)
%% %% Affichage des scopes pour C(z) avec consigne 1.75V et retour 1.65V
figure(4)
plot(Sigma.time,Sigma.signals.values)
hold on
plot(Erreur2.time,Erreur2.signals.values)
hold off
legend('Sigma','Erreur')





