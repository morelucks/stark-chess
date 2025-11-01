use starknet::{ContractAddress, get_caller_address};
use dojo::model::ModelStorage;
use dojo::event::EventStorage;
use crate::models::{StakePot, PredictorStake, ChessGame, GameStatus};

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct StakeCommitted {
    #[key]
    pub game_id: u32,
    pub player: ContractAddress,
    pub amount: u128,
    pub is_white: bool,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct PredictionCommitted {
    #[key]
    pub game_id: u32,
    pub predictor: ContractAddress,
    pub amount: u128,
    pub on_white: bool,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct PotSettled {
    #[key]
    pub game_id: u32,
    pub winner_is_white: bool,
    pub total_paid: u128,
}

#[starknet::interface]
pub trait IStakePool<T> {
    fn commit_player_stake(ref self: T, game_id: u32, is_white: bool, amount: u128);
    fn commit_prediction(ref self: T, game_id: u32, on_white: bool, amount: u128);
    fn lock_pot(ref self: T, game_id: u32);
    fn settle_pot(ref self: T, game_id: u32);
    fn get_pot(ref self: T, game_id: u32) -> (u128, u128, bool);
}

#[dojo::contract]
pub mod stake_pool {
    use super::{IStakePool, StakeCommitted, PredictionCommitted, PotSettled};
    use crate::models::{StakePot, PredictorStake, ChessGame, GameStatus};
    use dojo::model::ModelStorage;
    use dojo::event::EventStorage;
    use starknet::{ContractAddress, get_caller_address};

    #[abi(embed_v0)]
    impl StakePoolImpl of IStakePool<ContractState> {
        fn commit_player_stake(ref self: ContractState, game_id: u32, is_white: bool, amount: u128) {
            let mut world = self.world_default();
            let caller = get_caller_address();
            assert!(amount > 0_u128, "amount=0");

            let game: ChessGame = world.read_model(game_id);
            assert!(game.status == GameStatus::Ongoing, "game not ongoing");

            let mut pot = world.try_read_model::<StakePot>(game_id).unwrap_or(StakePot{
                game_id,
                token: ContractAddress::from(0),
                white_stake: 0_u128,
                black_stake: 0_u128,
                is_locked: false,
            });
            assert!(!pot.is_locked, "pot locked");

            if is_white {
                pot.white_stake += amount;
            } else {
                pot.black_stake += amount;
            }
            world.write_model(@pot);

            world.emit_event(@StakeCommitted { game_id, player: caller, amount, is_white });
        }

        fn commit_prediction(ref self: ContractState, game_id: u32, on_white: bool, amount: u128) {
            let mut world = self.world_default();
            let predictor = get_caller_address();
            assert!(amount > 0_u128, "amount=0");

            let _game: ChessGame = world.read_model(game_id);

            let mut ps = world.try_read_model::<PredictorStake>((game_id, predictor)).unwrap_or(PredictorStake{
                game_id,
                predictor,
                on_white,
                amount: 0_u128,
            });
            assert!(ps.on_white == on_white || ps.amount == 0_u128, "side locked");
            ps.amount += amount;
            world.write_model(@ps);

            world.emit_event(@PredictionCommitted { game_id, predictor, amount, on_white });
        }

        fn lock_pot(ref self: ContractState, game_id: u32) {
            let mut world = self.world_default();
            let mut pot: StakePot = world.read_model(game_id);
            pot.is_locked = true;
            world.write_model(@pot);
        }

        fn settle_pot(ref self: ContractState, game_id: u32) {
            let mut world = self.world_default();
            let game: ChessGame = world.read_model(game_id);
            assert!(game.status != GameStatus::Ongoing, "game not ended");

            let mut pot: StakePot = world.read_model(game_id);
            let winner_is_white = match game.status {
                GameStatus::WhiteWins => true,
                GameStatus::BlackWins => false,
                _ => true, // default to white on draws for now
            };
            let total: u128 = pot.white_stake + pot.black_stake;

            // Note: actual token transfers are out of scope; this is a ledger placeholder.
            pot.white_stake = 0_u128;
            pot.black_stake = 0_u128;
            pot.is_locked = false;
            world.write_model(@pot);

            world.emit_event(@PotSettled { game_id, winner_is_white, total_paid: total });
        }

        fn get_pot(ref self: ContractState, game_id: u32) -> (u128, u128, bool) {
            let world = self.world_default();
            let pot: StakePot = world.read_model(game_id);
            (pot.white_stake, pot.black_stake, pot.is_locked)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"dojo_starter")
        }
    }
}



