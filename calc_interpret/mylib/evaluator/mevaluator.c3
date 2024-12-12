module mylib::evaluator::mevaluator;

import mylib::parser::mparser;
import std::math;

fn double! mevaluate(ASTNode* node) {

    switch (node.type)
    {
        case AST_NUMBER:
            return node.value.to_double()!;
        case AST_BINARY_OP:
            double left = mevaluate(node.left)!;
            double right = mevaluate(node.right)!;
            switch (node.value)
            {   
                case "+":
                    return left + right;
                case "-":
                    return left - right;
                case "/":
                    return left / right;
                case "*":
                    return left * right;
                case "%":
                    return left % right;
                default:
                    break;
                
            }
        case AST_FUNCION_CALL:
            double left = mevaluate(node.left)!;
            left = math::deg_to_rad(left);
            switch (node.value) {
                case "sin":
                    return math::sin(left);
                case "cos":
                    return math::cos(left);
                case "tan":
                    return math::tan(left);
                case "atan":
                    return math::atan(left);
                case "atan2":
                    unreachable("atan2 unimplemented");
                case "sqrt":
                    return math::sqrt(left);
                default:
                    break;
            }

        default:
            break;
        
    }

    return 0.00;
}