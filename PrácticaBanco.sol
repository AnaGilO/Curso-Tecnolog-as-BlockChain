// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// FUNCIONALIDADES BÁSICAS
// Cualquiera puede hacer un depósito de ETH, que queda asociado a su cuenta.
// En cualquier momento se puede retirar un depósito.
// Ofrecer un método para consultar el saldo propio el banco.
// El banco puede realizar préstamos con el dinero que tiene en depósito.
// En el momento en que alguien obtiene un préstamo, pasa a una lista de "deudores", de la que no se
// le retira hasta que ha devuelto todo el préstamo.
// Ofrecer un método para consultar el saldo deudor de cualquier cuenta.

// FUNCIONES INTERMEDIAS
// El contrato del banco puede llevar una cantidad de ETH precargada en el momento de la creación del
// contrato. Esta cantidad no pertenece a ninguna de las cuentas de los depositarios, obviamente.
// Añadir la restricción del "coeficiente de caja"

contract Banco {
    mapping (address => uint256) deudores;
    mapping (address => uint256) prestamos;
    mapping (address => uint256) balances;

    uint public coeficienteCaja;
    uint256 public interes;

    constructor() payable {
        balances[msg.sender] += msg.value;
        calcularCoeficienteCaja();
        interes = 5; // Consideramos un interes del 5%  
    }

    function calcularCoeficienteCaja() public {
        coeficienteCaja = (balances[msg.sender]*95)/100;
    }

    function depositar() public payable {
        uint256 eth_recibido = msg.value;
        balances[msg.sender] += eth_recibido;
    }

    function retirar(uint256 cantidad) public {
        // Debemos de comprobar si el usuario dispone del saldo suficiente
        require(balances[msg.sender] >= cantidad, "El usuario no tiene el saldo suficiente");
        require(consultarSaldoBanco() >= cantidad, "El banco no tiene el saldo suficiente");

        balances[msg.sender] -= cantidad;
        payable (msg.sender).transfer(cantidad);
    }

    function consultarSaldoBanco() view public returns (uint256) {
        return address(this).balance;
    }

    function solicitarPrestamo(uint256 cantidadPrestamo) public {
        // Restricciones a cumplir para poder solicitar el prestamo
        require((consultarSaldoBanco() >= cantidadPrestamo), "El banco no dispone del saldo suficiente");
        require((consultarSaldoBanco() >= coeficienteCaja), "El balance del banco no puede disminuir de su cinco por ciento total");
        require((calcularMaximoPrestamo() <= cantidadPrestamo), "Se ha solicitado un prestamo de mas valor del permitido");

        // Al pedir el prestamo, aumenta simultaneamente la deuda y el balance del usuario
        deudores[msg.sender] += cantidadPrestamo;
        balances[msg.sender] += cantidadPrestamo;
        payable (msg.sender).transfer(cantidadPrestamo);

        // Añadimos el usuario a la lista de deudores
        deudores[msg.sender] += cantidadPrestamo;
        // Apuntamos el importe del prestamo
        prestamos[msg.sender] = cantidadPrestamo;
    }

    // Funcion adicional: El maximo prestamo posible a sacar del banco se considera de forma propocional al saldo total del que dispone el banco
    // El valor calculado se devuelve como resultado de la función
    function calcularMaximoPrestamo() private view returns (uint256){ 
        // Consideramos el valor máximo como el 10 por ciento del saldo del banco 
        return (balances[address(this)] * 10)/100;
    }

    function pagarPrestamo() public payable {
        require(msg.value <= (deudores[msg.sender] + calcularInteres(msg.sender)), "El usuario aun no puede pagar su deuda");
        // El banco recibe la devolución del prestamo y el interes del mismo como beneficio
        balances[address(this)] += msg.value;
        balances[address(this)] += calcularInteres(msg.sender);
        calcularCoeficienteCaja();
        deudores[msg.sender] -= (msg.value + calcularInteres(msg.sender));
    }

    function calcularInteres(address deudor) private view returns (uint256) {
        // Calculamos el interes que le corresponde a este usuario
        require(prestamos[deudor] >= 0, "Este usuario no tiene ningun prestamo pendiente de pago");
        return (prestamos[deudor] * interes)/100;
    }

    function consultarDeudas(address direccionDeudor) public view returns (uint256) {
        return deudores[direccionDeudor];
    }
}
