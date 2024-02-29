// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract practicaAgenda {
    mapping (address => mapping(address => string)) agenda;

    // Utilizamos un mapping anidado para gestionar los permisos a los que puede acceder una cuenta
    mapping (address => mapping(address => bool)) permisos; 

    // Mapping anidado para gestionar durante cuanto tiempo (en segundos UNIX) una direccion tiene permiso para acceder a la agenda de otro usuario
    mapping (address => mapping(address => uint256)) tiempos;

    // Utilizamos otro mapping para cruzar los datos de la forma nombre => direccion. De dicha forma, también podremos buscar por nombre
    mapping (string => address) nombres;

    // Un usuario (msg.sender) le da permiso a otro de direccion asociada ad para acceder a su agenda
    function darPermiso (uint256 duracion, address ad) public {
        tiempos[ad][msg.sender] = block.timestamp;

        // Damos el permiso
        permisos[ad][msg.sender] = true;
        // Calculamos el tiempo que dura el permiso
        uint256 endTime = tiempos[ad][msg.sender] + duracion;
        
        if (block.timestamp >= endTime) {
            // Una vez terminado el tiempo especificado, revocamos el permiso
            permisos[ad][msg.sender] = false;
        }
    }

    // Comprobamos si una cuenta tiene permiso para acceder a otra 
    function comprobarPermiso(address ad) public view returns (bool) {
        return (permisos[msg.sender][ad]);
    }

    // Cada usuario puede crear su propia agenda
    function crearAgenda() public {
        // Cuando se crea una agenda, añadimos unicamente el propio contacto del propietario de la agenda (si no existía previamente)
        require(!compareStrings(agenda[msg.sender][msg.sender], "Propietario"), "El usuario ya dispone de una agenda");

        // Añadimos su propio contacto como referencia
        agenda[msg.sender][msg.sender] = "Propietario";

        // Le damos permiso para acceder a sus propios contactos
        permisos[msg.sender][msg.sender] = true;
    } 

    // Función auxiliar para comprobar si dos cadenas string son iguales
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    // Consultar un contacto (de su propia agenda)
    function consultarContactoPropio(address ad) public view  returns (string memory) {
        require(compareStrings(agenda[msg.sender][msg.sender], "Propietario"), "El usuario no dispone de una agenda");
        // En caso de que el contacto consultado no exista en la agenda, la función devolvera aquel valor que solidity asigne por defecto a las cadenas string, o "0" si ha sido previamente borrado
        return (agenda[msg.sender][ad]); 
    }

    // Consultar un contacto (ad) de otra agenda, con direccion asociada 'propietario' (unicamente si tiene permiso para hacerlo)
    function consultarContacto(address propietario, address ad) public view  returns (string memory) {
        require(compareStrings(agenda[propietario][propietario], "Propietario"), "No existe una agenda asociada a esta direccion");
        require(comprobarPermiso(propietario), "Este usuario no dispone del permiso necesario para acceder a esta agenda");

        // En caso de que el contacto consultado no exista en la agenda, la función devolvera aquel valor que solidity asigne por defecto a las cadenas string, o "0" si ha sido previamente borrado
        return (agenda[propietario][ad]); 
    }

    // Consultamos la direccion asociada a un nombre, pero posteriormente comprobamos si el usuario puede acceder a dicha información
    function consultarDireccion(string memory nombre) public view returns (address) {
        // Nota: Tal y como se ha implementado esta funcionalidad, si hay dos personas que se registran con un mismo nombre, la información del primer usuario se sobreescribirá con la del segundo usuario registrado
        // Para evitar este caso, sería necesario asegurar la exclusividad de los nombres introducidos, o bien utilizar un identificador único
        require(compareStrings(agenda[msg.sender][msg.sender], "Propietario"), "No existe una agenda asociada a esta direccion");
        // Si al consultar la dirección asociada a nombre en la agenda personal del usuario no se devuelve su mismo nombre, es que dicho contacto no estaba inicializado
        require(compareStrings(consultarContactoPropio(nombres[nombre]), nombre), "El usuario no tiene agregado a ningun contacto con este nombre");
        return nombres[nombre];
    }

    // Editar un contacto (el usuario solo puede acceder a su propia agenda)
    function editarContacto(address ad, string memory n) public {
        require(compareStrings(agenda[msg.sender][msg.sender], "Propietario"), "El usuario no dispone de una agenda");
        agenda[msg.sender][ad] = n;
        nombres[n] = ad;
    }

    // Borrar un contacto (el usuario solo puede acceder a su propia agenda)
    function borrarContacto(address ad) public {
        // En el caso de que el contacto no existiera ya previamente, la funcion no lanza un error
        require(compareStrings(agenda[msg.sender][msg.sender], "Propietario"), "El usuario no dispone de una agenda");
        agenda[msg.sender][ad] = "0";
    }
}
