use core::array::ArrayTrait;
use core::traits::TryInto;
use crate::models::{ChessPiece, PieceType, Position};

#[starknet::interface]
trait IMoveValidator<TContractState> {
    fn get_valid_moves(
        ref self: TContractState, 
        game_id: u32, 
        piece: ChessPiece, 
        rank: u8, 
        file: u8
    ) -> Array<Position>;
    
    fn is_valid_move(
        ref self: TContractState,
        game_id: u32,
        from_rank: u8,
        from_file: u8,
        to_rank: u8,
        to_file: u8
    ) -> bool;
    
    fn is_square_attacked(
        ref self: TContractState,
        game_id: u32,
        rank: u8,
        file: u8,
        by_color: u8
    ) -> bool;
}

#[dojo::contract]
mod move_validator {
    use super::*;
    use dojo::model::{ModelStorage}; 

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    #[storage]
    struct Storage {}

   #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"dojo_starter")
        }
    
        fn get_pawn_moves(
            self: @ContractState,
            game_id: u32,
            piece: ChessPiece,
            rank: u8,
            file: u8
        ) -> Array<Position> {
            let mut moves: Array<Position> = ArrayTrait::new();
            let mut world = self.world_default();
            
            let direction: u8 = if piece.color == 0_u8 { 1_u8 } else { 1_u8 }; 
        
            if rank + direction < 8_u8 {
                let new_rank = rank + direction;
                let target: ChessPiece = world.read_model((game_id, new_rank, file));
                if target.color == 2_u8 { 
                    moves.append(Position { rank: new_rank, file });
                    
                    if (piece.color == 0_u8 && rank == 1_u8) || (piece.color == 1_u8 && rank == 6_u8) {
                        if rank + direction + direction < 8_u8 {
                            let double_rank = new_rank + direction;
                            let double_target: ChessPiece = world.read_model((game_id, double_rank, file));
                            if double_target.color == 2_u8 {
                                moves.append(Position { rank: double_rank, file });
                            }
                        }
                    }
                }
            }

            if rank + direction < 8_u8 {
                let new_rank = rank + direction;

                if file > 0_u8 {
                    let target: ChessPiece = world.read_model((game_id, new_rank, file - 1_u8));
                    if target.color != 2_u8 && target.color != piece.color {
                        moves.append(Position { rank: new_rank, file: file - 1_u8 });
                    }
                }
                
                if file < 7_u8 {
                    let target: ChessPiece = world.read_model((game_id, new_rank, file + 1_u8));
                    if target.color != 2_u8 && target.color != piece.color {
                        moves.append(Position { rank: new_rank, file: file + 1_u8 });
                    }
                }
            }
            
            moves
        }

        fn get_rook_moves(
            self: @ContractState,
            game_id: u32,
            piece: ChessPiece,
            rank: u8,
            file: u8
        ) -> Array<Position> {
            let mut moves: Array<Position> = ArrayTrait::new();
            let mut world = self.world_default();
            
            let directions = array![(0, 1), (0, -1), (1, 0), (-1, 0)];

            let mut dir_idx = 0_u32;
            loop {
                if dir_idx >= directions.len() {
                    break;
                }
                let (dr, df) = *directions.at(dir_idx);
                
                let mut step = 1_u8;
                loop {
                    let rank_i32: i32 = rank.into();
                    let file_i32: i32 = file.into();
                    let step_i32: i32 = step.into();
                    
                    let new_rank_i32 = rank_i32 + dr * step_i32;
                    let new_file_i32 = file_i32 + df * step_i32;
                    
                    if new_rank_i32 < 0 || new_rank_i32 >= 8 || new_file_i32 < 0 || new_file_i32 >= 8 {
                        break;
                    }
                    
                    let new_rank: u8 = new_rank_i32.try_into().unwrap();
                    let new_file: u8 = new_file_i32.try_into().unwrap();
                    
                    let target: ChessPiece = world.read_model((game_id, new_rank, new_file));
                    
                    if target.color == 2_u8 {
                        moves.append(Position { rank: new_rank, file: new_file });
                    } else if target.color != piece.color {
                        moves.append(Position { rank: new_rank, file: new_file });
                        break; 
                    } else { 
                        break; 
                    }
                    
                    step += 1_u8;
                };
                dir_idx += 1_u32;
            };
            
            moves
        }

        fn get_knight_moves(
            self: @ContractState,
            game_id: u32,
            piece: ChessPiece,
            rank: u8,
            file: u8
        ) -> Array<Position> {
            let mut moves: Array<Position> = ArrayTrait::new();
            let mut world = self.world_default();
            
            let knight_moves = array![
                (-2, -1), (-2, 1), (-1, -2), (-1, 2),
                (1, -2), (1, 2), (2, -1), (2, 1)
            ];
            
            let mut i = 0_u32;
            loop {
                if i >= knight_moves.len() {
                    break;
                }
                let (dr, df) = *knight_moves.at(i);
                
                let rank_i32: i32 = rank.into();
                let file_i32: i32 = file.into();
                
                let new_rank_i32 = rank_i32 + dr;
                let new_file_i32 = file_i32 + df;
                
                if new_rank_i32 >= 0 && new_rank_i32 < 8 && new_file_i32 >= 0 && new_file_i32 < 8 {
                    let new_rank: u8 = new_rank_i32.try_into().unwrap();
                    let new_file: u8 = new_file_i32.try_into().unwrap();
                    
                    let target: ChessPiece = world.read_model((game_id, new_rank, new_file));
                    if target.color == 2_u8 || target.color != piece.color {
                        moves.append(Position { rank: new_rank, file: new_file });
                    }
                }
                i += 1_u32;
            };
            
            moves
        }
    }

    #[abi(embed_v0)]
    impl MoveValidatorImpl of super::IMoveValidator<ContractState> {
        fn get_valid_moves(
            ref self: ContractState, 
            game_id: u32, 
            piece: ChessPiece, 
            rank: u8, 
            file: u8
        ) -> Array<Position> {
            match piece.piece_type {
                PieceType::Pawn => self.get_pawn_moves(game_id, piece, rank, file),
                PieceType::Rook => self.get_rook_moves(game_id, piece, rank, file),
                PieceType::Knight => self.get_knight_moves(game_id, piece, rank, file),
                _ => ArrayTrait::new() 
        }
        }

        fn is_valid_move(
            ref self: ContractState,
            game_id: u32,
            from_rank: u8,
            from_file: u8,
            to_rank: u8,
            to_file: u8
        ) -> bool {
            let mut world = self.world_default();
            let piece: ChessPiece = world.read_model((game_id, from_rank, from_file));
            let valid_moves = self.get_valid_moves(game_id, piece, from_rank, from_file);
            
            let target = Position { rank: to_rank, file: to_file };
            let mut i = 0_u32;
            
            loop {
                if i >= valid_moves.len() {
                    break false;
                }
                if *valid_moves.at(i) == target {
                    break true;
                }
                i += 1_u32;
            }
        }

        fn is_square_attacked(
            ref self: ContractState,
            game_id: u32,
            rank: u8,
            file: u8,
            by_color: u8
        ) -> bool {
            let mut world = self.world_default();
            let mut attacking_rank = 0_u8;
            let mut found_attack = false;
            
            loop {
                if attacking_rank >= 8_u8 || found_attack {
                    break;
                }
                let mut attacking_file = 0_u8;
                
                loop {
                    if attacking_file >= 8_u8 {
                        break;
                    }

                    let piece: ChessPiece = world.read_model((game_id, attacking_rank, attacking_file));
                    if piece.color == by_color && piece.color != 2_u8 { 
                        let valid_moves = self.get_valid_moves(
                            game_id,
                            piece,
                            attacking_rank,
                            attacking_file
                        );
                        
                        let target = Position { rank, file };
                        let mut i = 0_u32;
                        
                        loop {
                            if i >= valid_moves.len() {
                                break;
                            }
                            if *valid_moves.at(i) == target {
                                found_attack = true;
                                break;
                            }
                            i += 1_u32;
                        };
                    }
                    attacking_file += 1_u8;
                };
                attacking_rank += 1_u8;
            };
            
            found_attack
        }
    }
}