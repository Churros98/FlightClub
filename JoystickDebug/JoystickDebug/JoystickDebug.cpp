// JoystickDebug.cpp : Ce fichier contient la fonction 'main'. L'exécution du programme commence et se termine à cet endroit.
//

#include <iostream>

#include <Windows.h>
#include "Joystick.h"

int main()
{
    Joystick joy;

    if (joy.IsJoystickInitialized() == false) {
        std::cout << "Unable to initialize joystick." << std::endl;
        return 0;
    }

    if (joy.IsJoystickConnected() == false) {
        std::cout << "No device found." << std::endl;
        return 0;
    }

    JoystickData inputData;
    while (true) {

        if (FAILED(joy.GetInput(&inputData)))
            break;

        std::cout << "pitch: " << inputData.pitch << " yaw: " << inputData.yaw << " roll: " << inputData.roll << " Throttle: " << inputData.power << std::endl;

        for (int i = 0; i < 20; i++) {
            if (inputData.allButtons[i]) {
                std::cout << "input #" << i << std::endl;
            }
        }

        Sleep(10);
    }

    delete &joy;


    return 0;
}

// Exécuter le programme : Ctrl+F5 ou menu Déboguer > Exécuter sans débogage
// Déboguer le programme : F5 ou menu Déboguer > Démarrer le débogage

// Astuces pour bien démarrer : 
//   1. Utilisez la fenêtre Explorateur de solutions pour ajouter des fichiers et les gérer.
//   2. Utilisez la fenêtre Team Explorer pour vous connecter au contrôle de code source.
//   3. Utilisez la fenêtre Sortie pour voir la sortie de la génération et d'autres messages.
//   4. Utilisez la fenêtre Liste d'erreurs pour voir les erreurs.
//   5. Accédez à Projet > Ajouter un nouvel élément pour créer des fichiers de code, ou à Projet > Ajouter un élément existant pour ajouter des fichiers de code existants au projet.
//   6. Pour rouvrir ce projet plus tard, accédez à Fichier > Ouvrir > Projet et sélectionnez le fichier .sln.
