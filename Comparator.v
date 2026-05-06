module Comparator(A,B,S,CLK,RegE,RegGT,RegLT);//Veronica Wakileh 1220245 Compartor module
input [5:0] A,B;//inputs
input S,CLK;
output RegE,RegLT,RegGT;//Outputs

wire [5:0] RegA, RegB,RegS,NotA,NotB,X,Y_GT,Y_LT;   
wire E,GT,LT,GT_unsigned,LT_unsigned,GT_signed,LT_signed,Y;

//Equality
genvar i;
generate
for(i = 0;i < 6;i++)
	begin
      DFF   FirstNumber (A[i],CLK,RegA[i]);
      DFF   SecondNumber (B[i],CLK,RegB[i]);
		DFF  Selection (S,CLK,RegS);
	 not #4 (NotA[i], RegA[i]);	//Used For Less Than 
     not #4 (NotB[i], RegB[i]);	//Used For Greater Than 
     xnor #9 (X[i], RegA[i], RegB[i]); 
    end
endgenerate
and #7 (E, X[5], X[4], X[3], X[2], X[1], X[0]);	//Check Equality

//Less Than: unsigned
and #7 (Y_LT[5],NotA[5],RegB[5]); 
and #7 (Y_LT[4],NotA[4],RegB[4],X[5]);
and #7 (Y_LT[3],NotA[3],RegB[3],X[5],X[4]);
and #7 (Y_LT[2],NotA[2],RegB[2],X[5],X[4],X[3]);	 
and #7 (Y_LT[1],NotA[1],RegB[1],X[5],X[4],X[3],X[2]);
and #7 (Y_LT[0],NotA[0],RegB[0],X[5],X[4],X[3],X[2],X[1]);	   
or #7 (LT_unsigned,Y_LT[5],Y_LT[4],Y_LT[3],Y_LT[2],Y_LT[1],Y_LT[0]);

//Greater Than: unsigned
and #7 (Y_GT [5],NotB[5],RegA[5]); 
and #7 (Y_GT [4],NotB[4],RegA[4],X[5]);
and #7 (Y_GT [3],NotB[3],RegA[3],X[5],X[4]);
and #7 (Y_GT [2],NotB[2],RegA[2],X[5],X[4],X[3]);	 
and #7 (Y_GT [1],NotB[1],RegA[1],X[5],X[4],X[3],X[2]);
and #7 (Y_GT [0],NotB[0],RegA[0],X[5],X[4],X[3],X[2],X[1]);	   
or #7 (GT_unsigned,Y_GT[5],Y_GT[4],Y_GT[3],Y_GT[2],Y_GT[1],Y_GT[0]);

//Greater Than: signed					 
nor #5 (Y,RegA[5],RegB[5]);
xnor #9 (GT_signed,GT_unsigned,Y);

//Greater Than: signed
xnor #9 (LT_signed,LT_unsigned,Y);

mux2to1 mux_LT(LT_unsigned,LT_signed,RegS,LT);
mux2to1 mux_GT(GT_unsigned,GT_signed,RegS,GT);	

DFF Equalty(E,CLK,RegE); 
DFF LessThan(LT,CLK,RegLT);
DFF GreaterThan(GT,CLK,RegGT);
endmodule

module mux2to1(x1, x2, s, f);//Veronica Wakileh 1220245 Mux module
input  x1, x2, s;
output f;
wire   k, g, h;
not #4 (k,s);
and #7 (g, k, x1);
and #7 (h, s, x2);
or #7 (f, g, h);
endmodule 

module DFF(D, Clock, Q);//Veronica Wakileh 1220245 DFF module

input  D; 
input Clock;
output reg  Q; 
always @(posedge Clock)
	begin Q <= D;
	end
endmodule  

module B_Comparator(A,B,S,EQ,GT,LT); //Veronica Wakileh 1220245 Behavioral comparator
input [5:0] A,B;
input S;
output reg EQ,GT,LT;
wire Sign_A = A[5],Sign_B = B[5];

always @(A,B,S) begin
	
	if (S) begin	
		GT = (!Sign_A & Sign_B)|((Sign_A == Sign_B) & (A > B)& (Sign_A == 0))|((Sign_A == Sign_B) & (A < B) & (Sign_A == 1));
		LT = (Sign_A & !Sign_B)|((Sign_A == Sign_B) & (A < B) & (Sign_A == 0))|((Sign_A == Sign_B) & (A > B) & (Sign_A == 1));
		EQ = (Sign_A == Sign_B) & (A == B);	 
end
	else begin
		GT = (A > B);
		LT = (A < B);
		EQ = (A == B); 
end
end
endmodule

module tb_comparator;//Veronica Wakileh 1220245 TestBench	   

reg S, CLK;	
reg [5:0] A, B;
wire LT,GT,EQ,Greaterthan,Lessthan,Equal;

integer Error_Counter = 0;//Used to detect Errors

Comparator Design(A,B,S,CLK,EQ,GT,LT);
B_Comparator BComparator(A,B,S,Equal,Greaterthan,Lessthan);

initial begin
	CLK = 0;
end

always #30 CLK = ~ CLK;	 

initial begin
	
	repeat (10)	begin 
	A = $random % 64; // Generate random 6-bit value
	B = $random % 64; // Generate random 6-bit value
	S = $random % 2;  // Generate random 1-bit value   
	#150
	Compare_outputs();
	end
	Print_Final_ErrorCount();
end

task Compare_outputs;	
begin 
	if ((EQ != Equal) || (GT != Greaterthan) || (LT != Lessthan)) begin	
		$display("Test Failed | Time: %0d | A = %b, B = %b, S = %b | Structural -> EQ=%b GT=%b LT=%b | Behavioral -> EQ=%b GT=%b LT=%b",$time,A,B,S,EQ,GT,LT,Equal,Greaterthan,Lessthan);
		Error_Counter = Error_Counter + 1;	 
	end else begin
	$display("Test Passed | Time: %0d | A = %b, B = %b, S = %b | EQ=%b GT=%b LT=%b",$time,A,B,S,EQ,GT,LT); 
end 
end
endtask

task Print_Final_ErrorCount;
begin
	if (Error_Counter > 0) begin
	$display("SIMULATION COMPLETED: %0d errors detected",Error_Counter);
	end
else 
	begin
		$display("SIMULATION COMPLETE: No errors detected");
	end
end
endtask

endmodule