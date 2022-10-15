pragma solidity ^0.8.0;

import "./interfaces/IPool.sol";
import "./interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Looping {
    using SafeMath for uint256;

    IUniswapV3Factory factory;
    ISwapRouter constant router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address aavePool = 0x794a61358D6845594F94dc1DB02A252b5b4814aD; //On Polygon

    constructor() {
        factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    }

    // Function to leverage on aave. Assumes this contract has the funds
    function loop(
        uint256 amount,
        address lvrTokenAddr,
        address stbTokenAddr,
        uint16 multiplier
    ) public {
        require(multiplier > 100, "You cannot leverage less than 1*");
        IPool pool = IPool(aavePool);
        IERC20 lvrToken = IERC20(lvrTokenAddr);
        // IERC20 stbToken = IERC20(stbTokenAddr);

        //Supply the lvrTokens to Aave
        lvrToken.approve(aavePool, amount);
        pool.supply(lvrTokenAddr, amount, msg.sender, 0);

        uint256 amountToBorrow = (getPrice(lvrTokenAddr, stbTokenAddr) *
            (multiplier - 100)) / 100;
        //Borrow the stable tokens
        pool.borrow(stbTokenAddr, amountToBorrow, 2, 0, address(this));

        //Swap the stable tokens for lvrTokens
        lvrToken.approve(0xE592427A0AEce92De3Edee1F18E0157C05861564, amount);
        swapExactInputSingleHop(
            stbTokenAddr,
            lvrTokenAddr,
            500,
            amountToBorrow
        );
        // Supply the obtained lvrTokens
        pool.supply(lvrTokenAddr, lvrToken.balanceOf(address(this)), msg.sender, 0);

    }

    function getPrice(address tokenIn, address tokenOut)
        public
        view
        returns (uint256 price)
    {
        IUniswapV3Pool pool = IUniswapV3Pool(
            factory.getPool(tokenIn, tokenOut, 500)
        );
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        return
            uint256(sqrtPriceX96).mul(uint256(sqrtPriceX96)).mul(1e18) >>
            (96 * 2);
    }

    function swapExactInputSingleHop(
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        IERC20(tokenIn).approve(address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = router.exactInputSingle(params);
    }
}
