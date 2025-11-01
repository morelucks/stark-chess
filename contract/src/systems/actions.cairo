use crate::models::{ PieceType, GameStatus, Position};
use starknet::{ContractAddress};

// Events
#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct GameStarted {
    #[key]
    pub game_id: u32,
    pub white_player: ContractAddress,
    pub black_player: ContractAddress,
    pub is_single_player: bool,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event] 
pub struct MoveMade {
    #[key]
    pub game_id: u32,
    pub player: ContractAddress,
    pub from_rank: u8,
    pub from_file: u8,
    pub to_rank: u8,
    pub to_file: u8,
    pub piece_type: PieceType,
    pub is_computer_move: bool,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct GameEnded {
    #[key]
    pub game_id: u32,
    pub winner: Option<ContractAddress>,
    pub status: GameStatus,
}

// Interface
#[starknet::interface]
pub trait IChessActions<T> {
    fn create_multiplayer_game(ref self: T, opponent: ContractAddress) -> u32;
    fn create_single_player_game(ref self: T) -> u32;
    fn make_move(ref self: T, game_id: u32, from_rank: u8, from_file: u8, to_rank: u8, to_file: u8);
    fn get_valid_moves(ref self: T, game_id: u32, rank: u8, file: u8) -> Array<Position>;
    fn get_game_state(ref self: T, game_id: u32) -> (Array<Array<Option<(PieceType, u8)>>>, u8, GameStatus);
    fn resign_game(ref self: T, game_id: u32);
}

#[dojo::contract]
pub mod chess_actions {
    use super::{IChessActions, GameStarted, MoveMade, GameEnded};
    use crate::models::{ChessGame, ChessPiece, PieceType, GameStatus, Position};
    use starknet::{ContractAddress, get_caller_address};
    use dojo::model::{ModelStorage};
    use dojo::event::EventStorage;
    
    // Computer player identifier
    const COMPUTER_PLAYER: felt252 = 0x434f4d5055544552; // "COMPUTER" in felt252
    
    #[abi(embed_v0)]
    impl ChessActionsImpl of IChessActions<ContractState> {
        
        fn create_multiplayer_game(ref self: ContractState, opponent: ContractAddress) -> u32 {
            let mut world = self.world_default();
            let creator = get_caller_address();
            
            let game_id = 1; 
            
            let new_game = ChessGame {
                game_id,
                white_player: creator,
                black_player: opponent,
                current_turn: 0,
                status: GameStatus::Ongoing,
                white_castle_rights: 3,
                black_castle_rights: 3,
                move_count: 0,
            };
            
            world.write_model(@new_game);
            self.initialize_board(ref world, game_id);
            
            world.emit_event(@GameStarted {
                game_id,
                white_player: creator,
                black_player: opponent,
                is_single_player: false,
            });
            
            game_id
        }
        
        fn create_single_player_game(ref self: ContractState) -> u32 {
            let mut world = self.world_default();
            let player = get_caller_address();
            
            let game_id = 1; // Simplified for hackathon
            
            // Convert computer identifier to ContractAddress
            let computer_address: ContractAddress = COMPUTER_PLAYER.try_into().unwrap();
            
            let new_game = ChessGame {
                game_id,
                white_player: player,        // Human is always white
                black_player: computer_address, // Computer is black
                current_turn: 0,             // Human starts first
                status: GameStatus::Ongoing,
                white_castle_rights: 3,
                black_castle_rights: 3,
                move_count: 0,
            };
            
            world.write_model(@new_game);
            self.initialize_board(ref world, game_id);
            
            world.emit_event(@GameStarted {
                game_id,
                white_player: player,
                black_player: computer_address,
                is_single_player: true,
            });
            
            game_id
        }
        
        fn make_move(
            ref self: ContractState, 
            game_id: u32, 
            from_rank: u8, 
            from_file: u8, 
            to_rank: u8, 
            to_file: u8
        ) {
            let mut world = self.world_default();
            let caller = get_caller_address();
            
            let game: ChessGame = world.read_model(game_id);
            let computer_address: ContractAddress = COMPUTER_PLAYER.try_into().unwrap();
            let is_single_player = game.black_player == computer_address;
            
            // For single player, only allow human to make moves directly
            if is_single_player {
                assert!(caller == game.white_player, "Only human player can make moves");
                assert!(game.current_turn == 0, "Not human's turn");
            } else {
                // Multiplayer validation
                assert!(
                    (game.current_turn == 0 && caller == game.white_player) ||
                    (game.current_turn == 1 && caller == game.black_player),
                    "Not your turn"
                );
            }
            
            assert!(game.status == GameStatus::Ongoing, "Game not ongoing");
            
            // Get piece and validate move
            let piece: ChessPiece = world.read_model((game_id, from_rank, from_file));
            assert!(piece.color == game.current_turn, "Not your piece");
            
            let valid_moves = self.get_valid_moves(game_id, from_rank, from_file);
            let target_position = Position { rank: to_rank, file: to_file };
            
            let mut move_valid = false;
            let mut i = 0;
            loop {
                if i >= valid_moves.len() {
                    break;
                }
                if *valid_moves.at(i) == target_position {
                    move_valid = true;
                    break;
                }
                i += 1;
            };
            
            assert!(move_valid, "Invalid move");
            
            // Execute human move
            self.execute_move(ref world, game_id, from_rank, from_file, to_rank, to_file);
            
            // Update game state
            let updated_game = ChessGame {
                game_id: game.game_id,
                white_player: game.white_player,
                black_player: game.black_player,
                current_turn: 1, // Switch to computer's turn
                status: game.status,
                white_castle_rights: game.white_castle_rights,
                black_castle_rights: game.black_castle_rights,
                move_count: game.move_count + 1,
            };
            world.write_model(@updated_game);
            
            // Emit human move event
            world.emit_event(@MoveMade {
                game_id,
                player: caller,
                from_rank,
                from_file,
                to_rank,
                to_file,
                piece_type: piece.piece_type,
                is_computer_move: false,
            });
            
            // If single player, trigger computer move
            if is_single_player {
                self.make_computer_move(ref world, game_id);
            }
        }
        
        fn get_valid_moves(ref self: ContractState, game_id: u32, rank: u8, file: u8) -> Array<Position> {
            let world = self.world_default();
            let piece: ChessPiece = world.read_model((game_id, rank, file));
            
            let mut moves = ArrayTrait::new();
            
            match piece.piece_type {
                PieceType::Pawn => {
                    let _direction = if piece.color == 0 { 1_u8 } else { 7_u8 }; 
                    
                    // Forward move
                    if (piece.color == 0 && rank < 7) || (piece.color == 1 && rank > 0) {
                        let new_rank = if piece.color == 0 { rank + 1 } else { rank - 1 };
                        let target: ChessPiece = world.read_model((game_id, new_rank, file));
                        if target.color == 2 { // Empty square
                            moves.append(Position { rank: new_rank, file });
                            
                            // Double move from starting position
                            if (piece.color == 0 && rank == 1) || (piece.color == 1 && rank == 6) {
                                let double_rank = if piece.color == 0 { rank + 2 } else { rank - 2 };
                                let double_target: ChessPiece = world.read_model((game_id, double_rank, file));
                                if double_target.color == 2 {
                                    moves.append(Position { rank: double_rank, file });
                                }
                            }
                        }
                        
                        // Captures
                        if file > 0 {
                            let target: ChessPiece = world.read_model((game_id, new_rank, file - 1));
                            if target.color != 2 && target.color != piece.color {
                                moves.append(Position { rank: new_rank, file: file - 1 });
                            }
                        }
                        if file < 7 {
                            let target: ChessPiece = world.read_model((game_id, new_rank, file + 1));
                            if target.color != 2 && target.color != piece.color {
                                moves.append(Position { rank: new_rank, file: file + 1 });
                            }
                        }
                    }
                },
                PieceType::King => {
                    // King moves in all 8 directions
                    let directions = array![
                        (0_i8, 1_i8), (0_i8, -1_i8), (1_i8, 0_i8), (-1_i8, 0_i8),
                        (1_i8, 1_i8), (1_i8, -1_i8), (-1_i8, 1_i8), (-1_i8, -1_i8)
                    ];
                    
                    let mut i = 0;
                    loop {
                        if i >= directions.len() {
                            break;
                        }
                        let (dr, df) = *directions.at(i);
                        
                        let rank_i32: i32 = rank.into();
                        let file_i32: i32 = file.into();
                        let new_rank_i32 = rank_i32 + dr.into();
                        let new_file_i32 = file_i32 + df.into();
                        
                        if new_rank_i32 >= 0 && new_rank_i32 < 8 && new_file_i32 >= 0 && new_file_i32 < 8 {
                            let new_rank: u8 = new_rank_i32.try_into().unwrap();
                            let new_file: u8 = new_file_i32.try_into().unwrap();
                            let target: ChessPiece = world.read_model((game_id, new_rank, new_file));
                            if target.color != piece.color {
                                moves.append(Position { rank: new_rank, file: new_file });
                            }
                        }
                        i += 1;
                    };
                },
                _ => {
                    // Other pieces not implemented yet
                }
            }
            
            moves
        }
        
        fn get_game_state(ref self: ContractState, game_id: u32) -> (Array<Array<Option<(PieceType, u8)>>>, u8, GameStatus) {
            let world = self.world_default();
            let game: ChessGame = world.read_model(game_id);
            
            let mut board = ArrayTrait::new();
            let mut rank = 0;
            loop {
                if rank >= 8_u8{
                    break;
                }
                let mut row = ArrayTrait::new();
                let mut file = 0;
                loop {
                    if file >= 8_u8{
                        break;
                    }
                    let piece: ChessPiece = world.read_model((game_id, rank, file));
                    if piece.color == 2 {
                        row.append(Option::None);
                    } else {
                        row.append(Option::Some((piece.piece_type, piece.color)));
                    }
                    file += 1;
                };
                board.append(row);
                rank += 1;
            };
            
            (board, game.current_turn, game.status)
        }
        
        fn resign_game(ref self: ContractState, game_id: u32) {
            let mut world = self.world_default();
            let player = get_caller_address();
            let game: ChessGame = world.read_model(game_id);
            
            assert!(
                player == game.white_player || player == game.black_player,
                "Not a player in this game"
            );
            
            let winner = if player == game.white_player { 
                game.black_player 
            } else { 
                game.white_player 
            };
            
            let updated_game = ChessGame {
                game_id: game.game_id,
                white_player: game.white_player,
                black_player: game.black_player,
                current_turn: game.current_turn,
                status: if player == game.white_player { GameStatus::BlackWins } else { GameStatus::WhiteWins },
                white_castle_rights: game.white_castle_rights,
                black_castle_rights: game.black_castle_rights,
                move_count: game.move_count,
            };
            
            world.write_model(@updated_game);
            
            world.emit_event(@GameEnded {
                game_id,
                winner: Option::Some(winner),
                status: updated_game.status,
            });
        }
    }
    
    // Internal helper functions
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"dojo_starter")
        }
        
        fn initialize_board(self: @ContractState, ref world: dojo::world::WorldStorage, game_id: u32) {
            // Initialize all squares as empty
            let mut rank = 0;
            loop {
                if rank >= 8 {
                    break;
                }
                let mut file = 0;
                loop {
                    if file >= 8 {
                        break;
                    }
                    world.write_model(@ChessPiece {
                        game_id,
                        rank,
                        file,
                        piece_type: PieceType::Pawn,
                        color: 2, // Empty
                    });
                    file += 1;
                };
                rank += 1;
            };
            
            // Set up starting pieces
            let back_pieces = array![
                PieceType::Rook, PieceType::Knight, PieceType::Bishop, PieceType::Queen,
                PieceType::King, PieceType::Bishop, PieceType::Knight, PieceType::Rook
            ];
            
            let mut file = 0;
            loop {
                if file >= 8 {
                    break;
                }
                
                // White pieces
                world.write_model(@ChessPiece {
                    game_id, rank: 0, file,
                    piece_type: *back_pieces.at(file.into()),
                    color: 0, // White
                });
                world.write_model(@ChessPiece {
                    game_id, rank: 1, file,
                    piece_type: PieceType::Pawn,
                    color: 0, // White
                });
                
                // Black pieces  
                world.write_model(@ChessPiece {
                    game_id, rank: 6, file,
                    piece_type: PieceType::Pawn,
                    color: 1, // Black
                });
                world.write_model(@ChessPiece {
                    game_id, rank: 7, file,
                    piece_type: *back_pieces.at(file.into()),
                    color: 1, // Black
                });
                
                file += 1;
            };
        }
        
        fn execute_move(
            self: @ContractState,
            ref world: dojo::world::WorldStorage,
            game_id: u32,
            from_rank: u8,
            from_file: u8,
            to_rank: u8,
            to_file: u8
        ) {
            let source_piece: ChessPiece = world.read_model((game_id, from_rank, from_file));
            
            // Move piece to destination
            let moved_piece = ChessPiece {
                game_id,
                rank: to_rank,
                file: to_file,
                piece_type: source_piece.piece_type,
                color: source_piece.color,
            };
            world.write_model(@moved_piece);
            
            // Clear source square
            world.write_model(@ChessPiece {
                game_id,
                rank: from_rank,
                file: from_file,
                piece_type: PieceType::Pawn,
                color: 2, // Empty
            });
        }
        
     // Add this inside your InternalImpl implementation
fn make_computer_move(
    self: @ContractState,
    ref world: dojo::world::WorldStorage,
    game_id: u32
) {
    // Find all possible computer (black) moves
    let mut computer_moves: Array<(u8, u8, u8, u8, PieceType)> = ArrayTrait::new();
    
    let mut rank = 0_u8;
    loop {
        if rank >= 8_u8 {
            break;
        }
        let mut file = 0_u8;
        loop {
            if file >= 8_u8 {
                break;
            }
            
            let piece: ChessPiece = world.read_model((game_id, rank, file));
            if piece.color == 1_u8 { // Black (computer) pieces
                // Collect valid moves for this piece
                let mut _i = 0_u8;
                let direction = if piece.color == 0_u8 { 1_u8 } else { 7_u8 };
                let new_rank = (rank + direction) % 8_u8;
                
                if new_rank < 8_u8 {
                    let target: ChessPiece = world.read_model((game_id, new_rank, file));
                    if target.color == 2_u8 { // Empty square
                        computer_moves.append((rank, file, new_rank, file, piece.piece_type));
                    }
                    
                    // Captures
                    if file > 0_u8 {
                        let target: ChessPiece = world.read_model((game_id, new_rank, file - 1_u8));
                        if target.color == 0_u8 { // White piece
                            computer_moves.append((rank, file, new_rank, file - 1_u8, piece.piece_type));
                        }
                    }
                    if file < 7_u8 {
                        let target: ChessPiece = world.read_model((game_id, new_rank, file + 1_u8));
                        if target.color == 0_u8 { // White piece
                            computer_moves.append((rank, file, new_rank, file + 1_u8, piece.piece_type));
                        }
                    }
                }
            }
            file += 1_u8;
        };
        rank += 1_u8;
    };
    
    if computer_moves.len() > 0_u32 {
        let (from_rank, from_file, to_rank, to_file, piece_type) = *computer_moves.at(0_u32);
        
        // Execute the move
        self.execute_move(ref world, game_id, from_rank, from_file, to_rank, to_file);
        
        // Update game state back to human's turn
        let game: ChessGame = world.read_model(game_id);
        let updated_game = ChessGame {
            game_id: game.game_id,
            white_player: game.white_player,
            black_player: game.black_player,
            current_turn: 0_u8, // Back to human's turn
            status: game.status,
            white_castle_rights: game.white_castle_rights,
            black_castle_rights: game.black_castle_rights,
            move_count: game.move_count + 1_u32,
        };
        world.write_model(@updated_game);
        
        // Emit move event
        let computer_address: ContractAddress = COMPUTER_PLAYER.try_into().unwrap();
        world.emit_event(@MoveMade {
            game_id,
            player: computer_address,
            from_rank,
            from_file,
            to_rank,
            to_file,
            piece_type,
            is_computer_move: true,
        });
    }
}
    }
}