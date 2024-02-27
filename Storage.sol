// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

 // Ejercicio 1: Modifica el contrato para que el valor almacenado lo combine usando una operación elemental con el valor anterior
 // Por ejemplo, para la multiplicación, si tengo 2 y almaceno 4, debería guardar 8.
contract Storage1 {

    uint256 number;

    // Para implementar la operación usa una función pure con dos argumentos
    function store1(uint256 num1, uint256 num2) public pure returns (uint256) {
        return num1 * num2;
    }

    // Para implementar la operación usa una función view con un solo argumento
    function store2(uint256 num) public view returns (uint256) {
        return number * num;
    }

    function retrieve() public view returns (uint256){
        return number;
    }
}

// Ejercicio 2: Observa el coste de almacenar el valor modificado y de consultar cual sería el valor nuevo llamando directamente a las funciones view y pure que no modifican el estado.
contract Storage2 {

    uint256 number;

    function store1(uint256 num1, uint256 num2) public pure returns (uint256) {
        return num1 * num2;
    }

    function retrieve() public view returns (uint256){
        return number;
    }
}

// Ejercicio 3: Comprueba errores de desbordamiento y división por cero con las operaciones aritméticas
contract Storage3 {

    uint256 number;

    function multiplicar (uint256 num) public {
        // Si el resultado de la multiplicacion es menor al valor anterior, ha debido de producirse un desbordamiento
        require((number*num)>number, "Se ha producido un desbordamiento");
        number *= num;
    }

    function dividir (uint256 num) public {
        // Si el resultado de la multiplicacion es menor al valor anterior, ha debido de producirse un desbordamiento
        require(num != 0, "El divisor de la operacion no puede ser cero");
        number *= num;
    }
}

// Ejercicio 4: El entorno de desarrollo remix no estima el coste de la función store
// Sin embargo, consultando información en internet, parece ser que el coste de ejecutar un smart contract no depende del tipo de dato utilizado sino de las operaciones ejecutadas

// Ejercicio 5: Implementa una restricción para que solo quién escriba un valor pueda leerlo, si es otro usuario debe recibir 0
contract Storage4 {
    uint256 number;
    address lastChangeAddress; // Dirección del último usuario que ha modificado el valor del smart contract 

    function store(uint256 num) public {
        number = num;
        lastChangeAddress = msg.sender;
    }

    function read() public view returns (uint256) {
        // Condición: el usuario que solicita leer el valor number debe de ser el mismo que ha realizado la última modificación
        uint256 res = 0;
        if (msg.sender == lastChangeAddress) {
            // El usuario es el mismo
            res = number;
        }
        return res;
    }
}

// Ejercicio 6: Usa un constructor para darle el valor inicial
contract Storage6 {
    uint256 number;

    // Constructor: le asignamos un valor directamente en su primera ejecución
    constructor (uint256 num) {
        number = num;
    }

    function store(uint256 num) public {
        number = num;
    }

    function read() public view returns (uint256) {
        return number;
    }
}

// Ejercicio 7: Implementa una restricción para que solo quién despliega el contrato puede actualizar los valores
contract Storage7 {
    uint256 number;
    address deployAddress; 

    // Constructor: le asignamos un valor directamente en su primera ejecución y registramos la dirección del usuario que ha desplegado el contrato
    constructor (uint256 num) {
        number = num;
        deployAddress = msg.sender;
    }

    function store(uint256 num) public {
        // Añadimos la restricción del enunciado
        require (msg.sender == deployAddress, "Este usuario no puede modificar el valor almacenado en el smart contract");
        number = num;
    }

    function read() public view returns (uint256) {
        return number;
    }
}