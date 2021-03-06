//------------------------------------------------------------------------------
// Company:          UIUC ECE Dept.
// Engineer:         Stephen Kempf
//
// Create Date:    17:44:03 10/08/06
// Design Name:    ECE 385 Lab 6 Given Code - Incomplete ISDU
// Module Name:    ISDU - Behavioral
//
// Comments:
//    Revised 03-22-2007
//    Spring 2007 Distribution
//    Revised 07-26-2013
//    Spring 2015 Distribution
//    Revised 02-13-2017
//    Spring 2017 Distribution
//------------------------------------------------------------------------------


module ISDU (   input logic         Clk, 
									Reset,
									Run,
									Continue,
									
				input logic[3:0]    Opcode, 
				input logic         IR_5,
				input logic         IR_11, //serves as r7
				input logic         BEN,
				  
				output logic        LD_MAR,
									LD_MDR,
									LD_IR,
									LD_BEN,
									LD_CC,
									LD_REG,
									LD_PC,
									LD_LED, // for PAUSE instruction
									
				output logic        GatePC,
									GateMDR,
									GateALU,
									GateMARMUX,
									
				output logic [1:0]  PCMUX,
				output logic        DRMUX,
									SR1MUX,
									SR2MUX,
									ADDR1MUX,
				output logic [1:0]  ADDR2MUX,
									ALUK,
				  
				output logic        Mem_CE,
									Mem_UB,
									Mem_LB,
									Mem_OE,
									Mem_WE
				);

	enum logic [4:0] {  Halted, 
						PauseIR1, 
						PauseIR2, 
						Pse,
						Pse2,
						S_18, 
						S_33_1, 
						S_33_2,
						S_05,
						S_09,
						S_06,
						S_25_1,
						S_25_2,
						S_27,
						S_07,
						S_23,
						S_16_1,
						S_16_2,
						S_04,
						S_21,
						S_12,
						S_00,
						S_22,
						S_35, 
						S_32, 
						S_01}   State, Next_state;   // Internal state logic
		
	always_ff @ (posedge Clk)
	begin
		if (Reset) 
			State <= Halted;
		else 
			State <= Next_state;
	end
   
	always_comb
	begin 
		// Default next state is staying at current state
		Next_state = State;
		
		// Default controls signal values
		LD_MAR = 1'b0;
		LD_MDR = 1'b0;
		LD_IR = 1'b0;
		LD_BEN = 1'b0;
		LD_CC = 1'b0;
		LD_REG = 1'b0;
		LD_PC = 1'b0;
		LD_LED = 1'b0;
		 
		GatePC = 1'b0;
		GateMDR = 1'b0;
		GateALU = 1'b0;
		GateMARMUX = 1'b0;
		 
		ALUK = 2'b00;
		 
		PCMUX = 2'b00;
		DRMUX = 1'b0;
		SR1MUX = 1'b0;
		SR2MUX = 1'b0;
		ADDR1MUX = 1'b0;
		ADDR2MUX = 2'b00;
		 
		Mem_OE = 1'b1;
		Mem_WE = 1'b1;
	
		// Assign next state
		unique case (State)
			Halted : 
				if (Run) 
					Next_state = S_18;                      
			S_18 : 
				Next_state = S_33_1;
			// Any states involving SRAM require more than one clock cycles.
			// The exact number will be discussed in lecture.
			S_33_1 : 
				Next_state = S_33_2;
			S_33_2 : 
				Next_state = S_35;
			S_35 : 
				Next_state = S_32;
			// PauseIR1 and PauseIR2 are only for Week 1 such that TAs can see 
			// the values in IR.
			PauseIR1 : 
				if (~Continue) 
					Next_state = PauseIR1;
				else 
					Next_state = PauseIR2;
			PauseIR2 : 
				if (Continue) 
					Next_state = PauseIR2;
				else 
					Next_state = S_18;
			S_32 : 
				case (Opcode)
					4'b0001 :    //ADD
						Next_state = S_01;
					4'b0101 :           //AND
						Next_state = S_05;
					4'b0000 :          //BRANCH
						Next_state = S_00;
					4'b1100 :          //JMP
						Next_state = S_12;
					4'b0100:        //JSR
						Next_state = S_04;
					4'b0110: ///LDR
						Next_state = S_06;
					4'b1001: //NOT
						Next_state = S_09;
					4'b0111: //STORE
						Next_state = S_07;
					4'b1101: //PSE implementation
						Next_state = Pse; //they wanted pause, we give em pause
					default : 
						Next_state = S_18;
				endcase
			S_01 : 
				Next_state = S_18;
			S_05 :
				Next_state = S_18;
			S_09 :
				Next_state = S_18;
			S_06 :
				Next_state = S_25_1;
			S_25_1:
				Next_state = S_25_2;
			S_25_2:
				Next_state = S_27;
			S_27:
				Next_state = S_18;
			S_07:
				Next_state = S_23;
			S_23:
				Next_state = S_16_1;
			S_16_1:
				Next_state = S_16_2;
			S_16_2:
				Next_state = S_18;
			S_04:
				Next_state = S_21;
			S_21:
				Next_state = S_18;
			S_12:
				Next_state = S_18;
			S_00:
				if(BEN)
					Next_state = S_22;
				else
					Next_state = S_18;
			S_22:
				Next_state = S_18;
			// You need to finish the rest of states.....

			default : ;

		endcase
		
		// Assign control signals based on current state
		case (State)
			Halted: 
				begin
					Mem_OE = 1'b1;
					Mem_WE = 1'b1;
				end
			S_18 :    //MAR<-PC, PC<-PC+1
				begin 
					GatePC = 1'b1;  //pcgatemux is 1
					LD_MAR = 1'b1; // marc is 1
					PCMUX = 2'b00;   //pcmux select is 00
					LD_PC = 1'b1;   //ld_Pc = 1
					Mem_OE = 1'b1;
					Mem_WE = 1'b1;
				end
			S_33_1 : 
				begin //M(MAR) into MDR
				Mem_OE = 1'b0;
				Mem_WE = 1'b1;
				end
			S_33_2 : 
				begin 
					Mem_OE = 1'b0;
					Mem_WE = 1'b1;
					LD_MDR = 1'b1;
				end
			S_35 : //MDR INTO IR
				begin 
					GateMDR = 1'b1;
					LD_IR = 1'b1;
					Mem_OE = 1'b1;
					Mem_WE = 1'b1;
				end
			PauseIR1: 
				begin
					Mem_OE = 1'b1;
					Mem_WE = 1'b1;
				end
			PauseIR2: 
				begin
					Mem_OE = 1'b1;
					Mem_WE = 1'b1;
				end
			S_32 : 
			begin
				LD_BEN = 1'b1;
					Mem_OE = 1'b1;
					Mem_WE = 1'b1;
					end
			S_01 :  //ADD
				begin 
					SR2MUX = IR_5;
					SR1MUX = 1'b1; //selects IR[8:6]
					ALUK = 2'b00; //add
					GateALU = 1'b1;
					LD_REG = 1'b1;
					LD_CC = 1'b1;
					Mem_OE = 1'b1;
					Mem_WE = 1'b1;
				end
			S_05 : //AND
				begin
					SR2MUX = IR_5;
					SR1MUX = 1'b1;
					ALUK = 2'b01; //and functions
					GateALU = 1'b1;
					LD_REG = 1'b1;
					LD_CC = 1'b1;
					Mem_OE = 1'b1;
					Mem_WE = 1'b1;
				end
			S_09 : //not functions
				begin
					SR1MUX = 1'b0;
					ALUK = 2'b10; //this is not function
					GateALU = 1'b1;
					LD_REG = 1'b1;
					LD_CC = 1'b1;
					Mem_OE = 1'b1;
					Mem_WE = 1'b1;
				end
			S_00: ;//BR(BEN) idk, this state really should do shit;
			S_22: //pc offset
				begin
				ADDR1MUX = 1'b0; //selects PC
				ADDR2MUX = 2'b10; //9bit sext
				PCMUX = 2'b01; //from the adu
				LD_PC = 1'b1;
				Mem_OE = 1'b1;
					Mem_WE = 1'b1;
				end
			S_06:  //MAR <- B +off6
				begin
				SR1MUX = 1'b1;
				ADDR1MUX = 1'b1;
				ADDR2MUX = 2'b01;
				GateMARMUX = 1'b1;
				LD_MAR = 1'b1;
				end
			S_25_1: //MDR-<M(MAR)
				begin
				Mem_WE = 1'b1;
				Mem_OE = 1'b0;
				end
			S_25_2:
				begin
				Mem_WE = 1'b1;
				Mem_OE = 1'b0;
				LD_MDR = 1'b1;
				end
			S_07:  //MAR-< B+off 6
				begin
				SR1MUX = 1'b1;
				ADDR1MUX = 1'b1;
				ADDR2MUX = 2'b01;
				GateMARMUX = 1'b1;
				LD_MAR = 1'b1;
				end
			S_23: //MDR-<SR
				begin
				SR1MUX = 1'b0;
				ALUK = 2'b11;
				GateALU = 1;
				LD_MDR = 1'b1;
				end
			S_16_1:  //MDR-<M(MAR)
				begin
				Mem_OE = 1'b1;
				Mem_WE = 1'b0;
				end
			S_16_2:  //MDR-<M(MAR)
				begin
				Mem_OE = 1'b1;
				Mem_WE = 1'b0;
				end
			S_04: //PC-<r7
				begin
				GatePC = 1'b1;
				DRMUX = IR_11;
				LD_REG = 1'b1;
				end
			S_21: ///pc-<PC + off11
				begin
				ADDR1MUX = 1'b0;
				ADDR2MUX = 2'b11;
				PCMUX = 2'b01;
				LD_PC = 1'b1;
				end
			S_12: //PC<-BASER
				begin
				SR1MUX = 1'b1;
				ADDR1MUX = 1'b1;
				ADDR2MUX = 2'b00;
				PCMUX = 2'b01;
				LD_PC = 1'b1;
				end
			Pse:
				begin
				Mem_OE = 1'b1;
				Mem_WE = 1'b1;
				LD_LED = 1'b1;
				end
			Pse2:
				begin
				Mem_OE = 1'b1;
				Mem_WE = 1'b1;
				end
			// You need to finish the rest of states.....

			default : 
			begin
				Mem_OE = 1'b1;
				Mem_WE = 1'b1;
				end
		endcase
	end 

	 // These should always be active
	assign Mem_CE = 1'b0;
	assign Mem_UB = 1'b0;
	assign Mem_LB = 1'b0;
	
endmodule
