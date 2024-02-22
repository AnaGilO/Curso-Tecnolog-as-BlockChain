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

contract Banco {
    mapping (address => uint256) deudores;
    mapping (address => uint256) balances;

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
        require((consultarSaldoBanco() >= cantidadPrestamo), "El banco no dispone del saldo suficiente");

        // Al pedir el prestamo, aumenta simultaneamente la deuda y el balance del usuario
        deudores[msg.sender] += cantidadPrestamo;
        balances[msg.sender] += cantidadPrestamo;
        payable (msg.sender).transfer(cantidadPrestamo);

        // Añadimos el usuario a la lista de deudores
        deudores[msg.sender] += cantidadPrestamo;
    }

    function pagarPrestamo() public payable {
        require(msg.value <= deudores[msg.sender], "El usuario aún no puede pagar su deuda");
        
    }

    function consultarDeudas(address direccionDeudor) public view returns (uint256) {
        return deudores[direccionDeudor];
    }

}
