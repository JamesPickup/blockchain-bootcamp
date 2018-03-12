pragma solidity ^0.4.19;

import './Battleships.sol';


contract BattleshipsV1 is Battleships {

    mapping(address => address) private opponents;
    mapping(address => uint8[][]) private boards;
    mapping(address => bool) private currentPlayer;

    uint8[8][8] private defaultBoard;

    enum ShipTypes { Tug, Frigate, Destroyer, Battleship, Carrier }

    function BattleshipsV1()
        public
    {

    }

    modifier notAlreadyPlaying(address player) {
        require(opponents[player] == address(0));
        _;

    }

    function startGame(address opponent)
        external
        notAlreadyPlaying(msg.sender)
        notAlreadyPlaying(opponent)
    {
        address player = msg.sender;
        opponents[player] = opponent;
        opponents[opponent] = player;

        boards[player] = defaultBoard;
        boards[opponent] = defaultBoard;

        GameStarted(player, opponent);
    }

    /**
     * gets your opponent's address
     * @return the address of your current opponent. Returns 0x0 if youare not playing.
     */
    function getOpponent()
        external
        view
        returns (address)
    {
        return opponents[msg.sender];
    }

    /**
     * Get the current content of the nominated cell for the player.
     * Results are either `0` for nothing, or the uint8 representing the ship type.
     * If a hits on a ship account for more than 50% of its size then it is sunk
     * and the ship is removed from the board. If this happens emit a `ShipSunk` event.
     * @param x The horizontal grid location of the player's grid cell.
     * @param y The vertical grid location of the player's grid cell.
     */
    function getCell(uint8 x, uint8 y)
        external
        view
        returns (uint8)
    {
        return boards[msg.sender][x][y];
    }

    /**
     * Have all of the ships of the given type been placed?
     * @param shipType The type of ship you are checking on, or if 0 it checks all ship types.
     * @return true if all the ships of the given type have been placed.
     *
     *   | Type       | size  | count | sum
     * 1 | Tug        | 1 x 1 | 1     | 1
     * 2 | Frigate    | 1 x 2 | 2     | 4
     * 3 | Destroyer  | 1 x 3 | 2     | 6
     * 4 | Battleship | 1 x 4 | 2     | 8
     * 5 | Carrier    | 2 x 5 | 1     | 10
     *     Total                        29
     */
    function allShipsPlaced(uint8 shipType)
        external
        view
        returns (bool)
    {
        /* All cells will have to checked anyone, so front load that work. */
        uint8[6] memory expectedCounts = [29, 1, 4, 6, 8, 10];
        uint8[6] memory cellCounts;
        for (uint8 x = 0; x < 8; ++x) {
            for (uint8 y = 0; y < 8; ++y) {
                uint8 cellType = boards[msg.sender][x][y];
                if (cellType != 0) {
                    cellCounts[cellType] += 1;
                    cellCounts[0] += 1;
                }
            }
        }

        return cellCounts[shipType] == expectedCounts[shipType];
    }

    /**
     * The address of the player whose turn it is.
     * @return the current player's address.
     */
    function whoseTurn()
        external
        view
        returns (address)
    {
        if (currentPlayer[msg.sender]) {
            return msg.sender;
        } else {
            return opponents[msg.sender];
        }
    }

    /**
     * Check if the game is still going.
     * @return true if the one of the players has no remaining ships.
     */
    function isGameOver()
        external
        view
        returns (bool)
    {
        return isBoardCleared(msg.sender) || isBoardCleared(opponents[msg.sender]);
    }

    /**
     * Check if a players board has been cleared
     * @return true if the player has no remaining ships
     */
    function isBoardCleared(address player)
        internal
        view
        returns(bool)
    {
        for (uint8 x = 0; x < 8; ++x) {
            for (uint8 y = 0; y < 8; ++y) {
                uint8 cellType = boards[player][x][y];
                if (cellType > 0) {
                    return false;
                }
            }
        }
        return true;
    }

}