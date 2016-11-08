contract AccessControlContractInterface {

    function can(bytes32 _sha3Verb, address _contractCaller, address originCaller, bytes extraData) returns (bool);

}

contract AccessControlGroupInterface {

    function isMember(address _user) returns (bool);
}

contract RuleOpInterface {
    function execute(uint32 session, uint ic, uint ip, bytes32 param1, bytes32 param2, bytes32 _verb, address _contractCaller, address originCaller, bytes extraData) returns (bool accept, bool reject, uint nexti);
}


contract AccessControlContract {

    struct Verb {
        bytes32 id;
        bytes32[] roleIds;
        uint[] roleIdx;
        uint idx;
    }

    mapping (bytes32 => Verb) verbs;
    bytes32[] verbIds;

    struct Role {
        bytes32 id;
        uint priority;
        bytes32[] verbIds;
        Rule[] acl;
        uint idx;
    }

    mapping (bytes32 => Role) roles;
    bytes32[] roleIds;


    address constant OP_ACCEPT = 1;
    address constant OP_REFECT = 0;

    struct Rule {
        uint idx;
        address op;
        bytes32 param1;
        bytes32 param2;
    }


    function AccessControlContract() {
        doUpdateRole(
            "superadmin",
            [
                "insert_role",
                "update_role",
                "delete_role"
            ],
            [ ACCEPT_IF_CALLER, msg.sender, 0]
            );
    }


    function can(bytes32 _verb, address _contractCaller, address _originCaller, bytes _extraData) returns (bool) {
        verb -> rol
        rol -> rules
        rule -> group
        rule -> person


        Verb verb = verbs[_verb];

        bool result=false;
        uint priority=0;

        for (i=0; i< verb.roleIds.length) {
            Role role = roles[roleIds[i]];
            if ((role.priority > priority) || (!result)) {
                if (runAcl(role.acl, _verb, _contractCaller, _originCaller, _extraData) return true;
            }
        }
        return false;
    }

    function runAcl(bytes32[] _acl, bytes32 _verb, address _contractCaller, address _originCaller, bytes _extraData) internal {
        bytes32 sessionId = sha3(msg.sender, txId++, block.blockhash(block.number -1));
        uint ip = 0;
        uint ic = 20;
        while (ic>0) {
            RuleOpInterface op = RuleOpInterface(_acl[ip*3]);
            bytes32 param1 = _acl[ip*3+1];
            bytes32 param2 = _acl[ip*3+2];
            var (accept, reject, nexti) = op.execute(sessionId, ic, ip, param1, param2, _verb, _contractCaller, _originCaller, _extraData);
            if (accept) return true;
            if (reject) return false;
            ip = nexti;
            ic --;
        }
        return false;
    }



    function updateRole(bytes32 name, byte32[] verbs, bytes32[] acl) can("update_role", name) {
        doUpdateRole(_name, _verbs, _acl);
    }

    function deleteRole(bytes32 name) can("delete_role", name) {
        doDeleteRole(_name, _verbs, _acl);
    }

    function doUpdateRole(bytes32 name, byte32[] verbs, bytes32[] acl) internal {
        doDelete(name);
        Role role = roles[_name];
        if (role.idRole == 0) {
            role.idRole = _name;
            role.idx = roles.length;
            roleIds[roles.length ++];
        }

        role.acl = _acl;
        role.verbIds = _verbs;

        for (i=0; i< role.verbIds; i++) {
            Verb verb = verbs[ role.verbIds[i]];
            if (verb.idVerb == 0) {
                verb.idVerb = role.verbIds[i];
                varb.idx = verbIds.length;
                verbIds[verbIds.length ++] = name;
            }

            verb.roleIdx[role.idRole] = verb.rolesIds.length;
            verb.rolesIds[verb.roles.length ++] = verb.idVerb;
        }

    }

    function doDelete(bytes32 _name) internal {
        Role role = roles[_name];
        if (role.idRole == 0) return;

        for (uint i=0; i<role.verbIds; i++) {
            Verb verb = verbs[role.verbIds[i]];

            uint idx = verb.roleIdx[_name];

            bytes32 lastRoleName = verb.roleIds[verb.roleIds.length-1];

            verb.roleIdx[lasRoleName] = idx;
            verb.roleIds[idx] = lastRoleName;
            verb.roleIds.length --;
            verb.roleIdx[lasRoleName] =0;


            // If verb has no role, remove it
            if (verb.roleIds.length =0) {
                verb.id = 0;

                lastVerbId = verbIds[verbIds.length-1];

                verbs[lastVerbId].idx = verb.idx;
                verbIds[idx] = lastVerbId;
                verbIds.length --;
                verb.idx =0;
            }
        }

        role.id = 0;

        // Delete acl

        for (i=0; i<role.acl.length; i++) {
            role.acl[i]=0;
        }
        role.acl.length = 0;

        // delete verbs

        for (i=0; i<role.verbs.length; i++) {
            role.verbs[i] =0;
        }
        role.verbs.length =0;


        // Remove role from the list
        lastRoleName = roleIds[roleIds.length-1];

        roles[lastRoleName].idx = role.idx;
        roleIds[idx] = lastRoleName;
        roleIds.length --;
        role.idx =0;

    }


}
