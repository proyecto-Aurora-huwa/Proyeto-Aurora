// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title HuwaToken (HW) - Proyecto Aurora
 * @dev Implementación de la moneda Huwa con lógica de paridad 1:1 USD,
 * sistema de custodia compartida y fondo de resguardo del 1%.
 */
contract HuwaToken {
    // 1. Parámetros del Token
    string public name = "Huwa";
    string public symbol = "HW";
    uint8 public decimals = 18;

    // 2. Seguridad y Gobernanza (Custodios)
    address public direccion;      // Dirección General (msg.sender)
    address public administracion; // Administración del Proyecto
    address public fondoResguardo; // Cuenta destinada al ahorro del 1%

    mapping(address => uint256) public balances;

    // Eventos para transparencia en la Blockchain
    event PagoRealizado(address indexed destinatario, uint256 monto, string tipo);
    event RespaldoCargado(uint256 monto);

    /**
     * @dev Constructor: Define quiénes son los custodios autorizados.
     */
    constructor(address _administracion, address _fondoResguardo) {
        direccion = msg.sender;
        administracion = _administracion;
        fondoResguardo = _fondoResguardo;
    }

    /**
     * @dev Protocolo de Emisión: Respaldo Previo.
     * Carga el saldo en el contrato tras verificar el depósito en dólares.
     */
    function respaldarYCrear(uint256 monto) public {
        require(msg.sender == direccion, "Solo la Direccion puede autorizar el respaldo inicial");
        uint256 montoTotal = monto * 10**uint256(decimals);
        balances[direccion] += montoTotal;
        emit RespaldoCargado(monto);
    }

    /**
     * @dev Fase de Distribución: Ejecución de Pagos.
     * Aplica la retención del 1% según el tipo de receptor.
     * @param destinatario La billetera que recibe los Huwas.
     * @param monto Cantidad en unidades (ej. 100).
     * @param esEstudiante Si es TRUE, el incentivo llega al 100%. 
     * Si es FALSE (Tutores/Nomina), se requerira la retencion del 1%.
     */
    function ejecutarPago(address destinatario, uint256 monto, bool esEstudiante) public {
        // Consenso: Se requerira firma de Direccion o Administracion
        require(msg.sender == direccion || msg.sender == administracion, "No autorizado: se requerira firma de custodia");
        
        uint256 montoTotal = monto * 10**uint256(decimals);
        uint256 comision = 0;

        // Lógica de Sostenibilidad (Fase de Distribución)
        if (esEstudiante == false) {
            comision = (montoTotal * 1) / 100; // Retención del 1%
        }

        uint256 pagoFinal = montoTotal - comision;

        require(balances[direccion] >= montoTotal, "No hay suficiente respaldo cargado para esta operacion");

        // Movimiento de fondos
        balances[direccion] -= montoTotal;
        balances[destinatario] += pagoFinal;
        balances[fondoResguardo] += comision;

        // Registro de transparencia
        string memory tipo = esEstudiante ? "Incentivo Estudiante (100%)" : "Pago Operativo (99% + 1% Resguardo)";
        emit PagoRealizado(destinatario, pagoFinal, tipo);
    }

    /**
     * @dev Función para consultar el saldo de cualquier cuenta.
     */
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
}
