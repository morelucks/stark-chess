use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct ChessGame {
    #[key]
    pub game_id: u32,
    pub white_player: ContractAddress,
    pub black_player: ContractAddress,
    pub current_turn: u8,  // 0 = white, 1 = black
    pub status: GameStatus,
    pub white_castle_rights: u8,  // bits: queenside|kingside
    pub black_castle_rights: u8,  // bits: queenside|kingside
    pub move_count: u32,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct ChessPiece {
    #[key]
    pub game_id: u32,
    #[key]
    pub rank: u8,  // 0-7
    #[key] 
    pub file: u8,  // 0-7
    pub piece_type: PieceType,
    pub color: u8,  // 0 = white, 1 = black
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct GameMove {
    #[key]
    pub game_id: u32,
    #[key]
    pub move_number: u32,
    pub from_rank: u8,
    pub from_file: u8,
    pub to_rank: u8,
    pub to_file: u8,
    pub piece_type: PieceType,
    pub is_capture: bool,
    pub promotion_piece: Option<PieceType>,
    pub notation: felt252,
}

#[derive(Copy, Drop, Serde, Introspect, PartialEq)]
pub enum PieceType {
    Pawn,
    Rook,
    Knight,
    Bishop,
    Queen,
    King,
}

#[derive(Copy, Drop, Serde, Introspect, PartialEq)]
pub enum GameStatus {
    Ongoing,
    WhiteWins,
    BlackWins,
    Stalemate,
    InsufficientMaterial,
    Draw,
}

#[derive(Copy, Drop, Serde)]
pub struct Position {
    pub rank: u8,
    pub file: u8,
}

impl PositionPartialEq of PartialEq<Position> {
    fn eq(lhs: @Position, rhs: @Position) -> bool {
        lhs.rank == rhs.rank && lhs.file == rhs.file
    }
    fn ne(lhs: @Position, rhs: @Position) -> bool {
        !(lhs.rank == rhs.rank && lhs.file == rhs.file)
    }
}

#[derive(Copy, Drop, Serde)]
pub struct ChessMove {
    pub from: Position,
    pub to: Position,
    pub piece_type: PieceType,
    pub promotion: Option<PieceType>,
}

// Helper implementations
impl PieceTypeIntoFelt252 of Into<PieceType, felt252> {
    fn into(self: PieceType) -> felt252 {
        match self {
            PieceType::Pawn => 'p',
            PieceType::Rook => 'r',
            PieceType::Knight => 'n',
            PieceType::Bishop => 'b',
            PieceType::Queen => 'q',
            PieceType::King => 'k',
        }
    }
}

impl GameStatusIntoFelt252 of Into<GameStatus, felt252> {
    fn into(self: GameStatus) -> felt252 {
        match self {
            GameStatus::Ongoing => 'ongoing',
            GameStatus::WhiteWins => 'white_wins',
            GameStatus::BlackWins => 'black_wins',
            GameStatus::Stalemate => 'stalemate',
            GameStatus::InsufficientMaterial => 'insufficient',
            GameStatus::Draw => 'draw',
        }
    }
}

// --- Staking Models ---

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct StakePot {
    #[key]
    pub game_id: u32,
    pub token: ContractAddress, 
    pub white_stake: u128,
    pub black_stake: u128,
    pub is_locked: bool,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct PredictorStake {
    #[key]
    pub game_id: u32,
    #[key]
    pub predictor: ContractAddress,
    pub on_white: bool,
    pub amount: u128,
}