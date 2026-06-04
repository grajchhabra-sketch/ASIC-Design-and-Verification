class axi_env extends uvm_env;

`uvm_component_utils(axi_env)

axi_agent agent0;
axi_agent agent1;
axi_agent agent2;

axi_scoreboard sb;

function new(string name,
uvm_component parent);

super.new(name,parent);

endfunction


function void build_phase(uvm_phase phase);

agent0=
axi_agent::type_id::create
("agent0",this);

agent1=
axi_agent::type_id::create
("agent1",this);

agent2=
axi_agent::type_id::create
("agent2",this);

sb=
axi_scoreboard::type_id::create
("sb",this);

endfunction


function void connect_phase(uvm_phase phase);

agent0.mon.mon_ap.connect(sb.sb_port);

agent1.mon.mon_ap.connect(sb.sb_port);

agent2.mon.mon_ap.connect(sb.sb_port);

endfunction

endclass
