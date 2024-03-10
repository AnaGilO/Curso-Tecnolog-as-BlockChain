// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CargaVehiculosElectricos1 {
    // OPCIÓN 1
    // El usuario paga por adelantado un bono temporal de reserva, se puede fijar un mínimo y un máximo, con con la zona azul (SARE)
    // El contrato debe emitir un evento para que el cargador empiece a cargar. Pasado ese tiempo el cargador queda libre y se puede volver a usar por un nuevo usuario.

    uint256 constant maxCargadores = 32;

    // Datos del constructor
    uint256 cargadores_funcionando;
    uint256 coste_minuto; 

    address administrador;

    // En esta variable vamos almacenando los beneficios generados por el smart contract
    uint256 balanceContrato;

    // Eventos para gestionar los cargadores
    event CargadorComenzado();
    event CargadorLibre();

    // Tiempo que ha reservado cada uno de los usuarios
    mapping (address => uint256) inicio_reservas; 
    mapping (address => uint256) duracion_reservas; 

    // Mapping para gestionar si los cargadores están ocupados en el momento de ejecución (cada cargador tiene un identificador entre 1-32)
    mapping (uint256 => bool) cargadores_ocupados;

    constructor(uint256 cargadores, uint256 coste) payable  {
        require(cargadores <= maxCargadores, "El sistema puede gestionar un maximo de 32 cargadores");
        cargadores_funcionando = cargadores;
        coste_minuto = coste;
        administrador = msg.sender;
        balanceContrato = 0;
    }

    // Función para que el administrador saque los fondos del contrato
    function sacarFondos() public {
        require(msg.sender == administrador, "Solo el administrador puede sacar los fondos");
        
        // Transferir los fondos al administrador
        payable(administrador).transfer(balanceContrato);
        
        // Actualizar el balance del contrato
        balanceContrato = 0;
    }
    
    // Función para recibir fondos
    receive() external payable {
        balanceContrato += msg.value;
    }

    // Función para que un usuario pague por adelantado una reserva
    function pagarReserva(uint256 id_cargador, uint256 inicio_reserva, uint256 duracion_reserva) public payable {
        // Nota: Se considera que un usuario puede efectuar multiples reservas (pero a disintos cargadores)

        require(msg.value > 0, "Se debe enviar ether para pagar la reserva");
        require(!cargadores_ocupados[id_cargador], "El cargador solicitado esta actualmente ocupado");
        require(id_cargador>=1 && id_cargador<=32, "El identificador del cargador proporcionado no es valido");
        require(duracion_reserva >= inicio_reserva, "Introduce un rango de tiempo valido");
        
        // Registrar el inicio de la nueva reserva
        inicio_reservas[msg.sender] = inicio_reserva;
        duracion_reservas[msg.sender] = duracion_reserva;

        // Ocupar el cargador
        cargadores_ocupados[id_cargador] = true;

        // Añadir el coste de la reserva como beneficio del contrato
        balanceContrato += msg.value;
        
        // Emitir el evento para comenzar la carga
        emit CargadorComenzado();
    }

    // Función para liberar el cargador después de que haya pasado el tiempo de reserva
    function liberarCargador(uint256 id_cargador) public {
        require(block.timestamp >= inicio_reservas[msg.sender] + duracion_reservas[msg.sender], "El tiempo de reserva no ha terminado");
        require(cargadores_ocupados[id_cargador], "Este cargador no ha efectuado ninguna carga");

        // Reiniciar el estado del cargador
        cargadores_ocupados[id_cargador] = false;
        
        // Emitir un evento para indicar que el cargador está libre
        emit CargadorLibre();
    }
}


contract CargaVehiculosElectricos2 {
    // OPCIÓN 2
    // El usuario paga cuando se desconecta el coche lo que haya consumido
    // Suponemos que ya no se aceptan reservas, sino que la carga comienza en el momento en el que es solicitada

    uint256 constant maxCargadores = 32;

    // Datos del constructor
    uint256 cargadores_funcionando;
    uint256 coste_minuto; 

    address administrador;

    // En esta variable vamos almacenando los beneficios generados por el smart contract
    uint256 balanceContrato;

    // Eventos para gestionar los cargadores
    event CargadorComenzado();
    event CargadorLibre();

    // Tiempo que ha reservado cada uno de los usuarios
    mapping (address => uint256) inicio_carga; 
    mapping (address => uint256) final_carga; 

    // Mapping para gestionar si los cargadores están ocupados en el momento de ejecución (cada cargador tiene un identificador entre 1-32)
    mapping (uint256 => bool) cargadores_ocupados;

    constructor(uint256 cargadores, uint256 coste) payable  {
        require(cargadores <= maxCargadores, "El sistema puede gestionar un maximo de 32 cargadores");
        cargadores_funcionando = cargadores;
        coste_minuto = coste;
        administrador = msg.sender;
        balanceContrato = 0;
    }

    // Función para que el administrador saque los fondos del contrato
    function sacarFondos() public {
        require(msg.sender == administrador, "Solo el administrador puede sacar los fondos");
        
        // Transferir los fondos al administrador
        payable(administrador).transfer(balanceContrato);
        
        // Actualizar el balance del contrato
        balanceContrato = 0;
    }
    
    // Función para recibir fondos
    receive() external payable {
        balanceContrato += msg.value;
    }

    // Función para que un usuario pague por adelantado una reserva
    function empezar_carga(uint256 id_cargador) public payable {
        // Nota: Se considera que un usuario puede efectuar multiples reservas (pero a disintos cargadores)

        require(msg.value > 0, "Se debe enviar ether para pagar la reserva");
        require(!cargadores_ocupados[id_cargador], "El cargador solicitado esta actualmente ocupado");
        require(id_cargador>=1 && id_cargador<=32, "El identificador del cargador proporcionado no es valido");

        // Ocupar el cargador
        cargadores_ocupados[id_cargador] = true;

        // Registrar el inicio de la carga
        inicio_carga[msg.sender] = block.timestamp;
        
        // Emitir el evento para comenzar la carga
        emit CargadorComenzado();
    }

    // Función para liberar el cargador después de que haya pasado el tiempo de reserva
    function liberarCargador(uint256 id_cargador) public {
        require(cargadores_ocupados[id_cargador], "Este cargador no ha efectuado ninguna carga");

        // Registramos el final de la carga efectuada
        final_carga[msg.sender] = block.timestamp;

        // Calculamos el coste de la carga efectuada
        uint256 coste;
        coste = (final_carga[msg.sender] - inicio_carga[msg.sender])*coste_minuto;

        // Sumamos el coste de la carga al beneficio del contrato
        balanceContrato += coste; 

        // Reiniciar el estado del cargador
        cargadores_ocupados[id_cargador] = false;
        
        // Emitir un evento para indicar que el cargador está libre
        emit CargadorLibre();
    }
}
