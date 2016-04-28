\documentclass{easychair}
\usepackage{amssymb}
\usepackage{mathabx}
%include polycode.fmt

% ------------------------------------------------------------------------------
% - title and stuff

\title{Dealing with Common Binary Relations\\in First-Order Automated Reasoning}

\titlerunning{Dealing with Common Binary Relations}

\author{
  Koen Claessen
  \and 
  Ann Lilliestr{\"o}m
}

\authorrunning{Claessen, Lilliestr{\"o}m}

\institute{
  Chalmers University of Technology
  \email{\{koen,annl\}@@chalmers.se}
}

\begin{document}

\maketitle

% ------------------------------------------------------------------------------
% - some symbols

%format flip    (r) = r "^{\curvearrowleftright}"
%format neg     (r) = r "^{\neg{}}"
%format negflip (r) = r "^{\neg{}\curvearrowleftright}"

%format ^^  = "^{\curvearrowleftright}"
%format ^~  = "^{\neg{}}"
%format ^~^ = "^{\neg{}\curvearrowleftright}"

%format forall = "\forall{}\hspace{-0.1cm}"
%format exists = "\exists{}\hspace{-0.1cm}"
%format .      = ".\;"
%format not    = "\neg{}\hspace{-0.1cm}"
%format ~      = "\neg{}"
%format =>     = "\Rightarrow "
%format <=>    = "\Leftrightarrow "

%format R  = "R\hspace{-0.1cm}"
%format R_ = "R"

%format prop1 = "prop_1"
%format propa = "prop_a"
%format propb = "prop_b"
%format propn = "prop_n"

% ------------------------------------------------------------------------------
% - abstract

\begin{abstract}
We present a number of alternative ways of treating binary relations that commonly occur in first-order problems, in particular {\em equivalence relations} and {\em total orderings}. We show how such relations can be discovered syntactically in an input theory. We experimentally evaluate different treatments on problems from the TPTP, using resolution-based reasoning tools as well as instance-based tools. Our conclusions are that (1) it is beneficial to considering different treatments of binary relations as a user, and that (2) reasoning tools could benefit from using a preprocessor or even built-in support for certain binary relations.
\end{abstract}

% ------------------------------------------------------------------------------
% - introduction

\section{Introduction}

Most automated reasoning tools for first-order logic have some kind of built-in support for reasoning about equality. Why? Because equality is an extremely common binary relation, and there are great performance benefits from providing built-in support for equality. Together, these two advantages by far outweigh the cost of implementation.

Other common concepts for which there exists built-in support in many tools are associative/commutative operators; real-valued, rational-valued, and integer-valued arithmetic; and binary relations with transitivity-like axioms \cite{chaining}. Again, these concepts seem to appear often enough to warrant the extra cost of implementing special support in reasoning tools.

This paper is concerned with investigating what kind of special treatment we could give to commonly appearing binary relations, and what effect this treatment has in practice. For now, we are mainly looking at (1) what a user of a reasoning tool may do herself to optimize the treatment of these binary relations, and (2) how a preprocessing tool may be able to do this automatically. Adding built-in reasoning support in the tools themselves is not a main concern of this paper.

By ``treatment'' we mean any way of logically expressing the relation. For example, a possible treatment of a binary relation |R_| in a theory |T| may simply mean axiomatizing |R_| in |T|. But it may also mean transforming |T| into a satisfiability-equivalent theory |T'| where |R_| does not even syntactically appear.

For the purpose of this paper, we have decided to concentrate on three different kinds of relations: (1) {\em equivalence relations} and {\em partial equivalence relations}, (2) {\em total orderings} and {\em strict total orderings}, and (3) {\em reflexive, transitive} relations. The reason we decided to concentrate on these three are because (a) they appear frequently in practice, and (b) we found well-known ways but also novel ways of dealing with these.

The target audience for this paper is thus both people who use reasoning tools and people who implement reasoning tools.

% ------------------------------------------------------------------------------
% - properties of binary relations

\section{Common properties of binary relations} \label{sec:properties}

In this section, we take a look at commonly occurring properties of binary relations, which combinations of these are interesting for us to treat specially, and how we may go about discovering these.

\begin{figure}[t]
\begin{center}
\begin{code}
reflexive      ==  forall x      . R(x,x)
euclidean      ==  forall x,y,z  . R(x,y) && R(x,z) => R(y,z)
antisymmetric  ==  forall x,y    . R(x,y) && R(y,x) => x=y
transitive     ==  forall x,y,z  . R(x,y) && R(y,z) => R(x,z)
asymmetric     ==  forall x,y    . ~R(x,y) || ~R(y,x)
total          ==  forall x,y    . R(x,y) || R(y,x)
symmetric      ==  forall x,y    . R(x,y) => R(y,x)
coreflexive    ==  forall x,y    . R(x,y) => x=y
\end{code}
\end{center}
\vspace{-0.5cm}
\caption{Definitions of basic properties of binary relations}
\label{fig:props}
\end{figure}

Take a look at Fig.\ \ref{fig:props}. It lists 8 basic and common properties of binary relations. Each of these properties can be expressed using one logic clause, which makes it easy to syntactically identify the presence of such a property in a given theory.

\begin{figure}[t]
\begin{center}
\begin{tabular}{rl}
4945 & reflexive \\
2082 & euclidean \\
1874 & antisymmetric \\
1567 & transitive \\
784  & asymmetric / total \\
388  & symmetric \\
3    & coreflexive \\
(163 & other)
\end{tabular}
\end{center}
\vspace{-0.5cm}
\caption{Number of occurrences of binary relation properties in TPTP}
\label{fig:occurs}
\end{figure}

When we investigated the number of occurrences of these properties in an older version of the TPTP problem library \cite{tptp}, we ended up with the table in Fig.\ \ref{fig:occurs}. The table was constructed by gathering all clauses from all TPTP problems (after clausification), and keeping every clause that only contained a binary relation symbol and, possibly, equality. Each such clause was then categorized as an expression of a basic property of a binary relation symbol. We found only 163 such clauses that did not fit any of the 8 properties we chose as basic properties. These were all quite esoteric and did not seem to have a standard name in mathematics.

The table also contains occurrences where a {\em negated relation} was stated to have a certain property, and also occurrences where a {\em flipped relation} (a relation with its arguments swapped) was stated to have a certain property, and even occurrences of combined negated and flipped relations. This explains for example why the number of occurrences of total relations is the same as for asymmetric relations; if a relation is total, its negated relation is asymmetric and vice-versa.

We adopt the following notation. Given a property of binary relations |prop|, we define its {\em negated version}, which is denoted by |prop^~|. The property |prop^~| holds for |R_| if and only |prop| holds for |~R_|. Similarly, we define the {\em flipped version} of a property |prop|, which is denoted by |prop^^|. The property |prop^^| holds for |R_| if and only |prop| holds for the flipped version of |R_|. Using this notation, we can for example say that |total| is equivalent with |asymmetric^~|. Sometimes the property we call |euclidean| here is called |right euclidean|; the corresponding variant |left euclidean| can be denoted |euclidean^^|.

Using this notation on the 8 original basic properties from Fig.\ \ref{fig:props}, we end up with 32 new basic properties that we can use. However, as we have already seen, some of these are equivalent to each other.

This paper will look at 5 kinds of different relations, which can be defined as combinations of basic properties:
\begin{code}
equivalence relation            ==  {reflexive, symmetric, transitive}
partial equivalence relation    ==  {symmetric, transitive}
total ordering                  ==  {total, antisymmetric, transitive}
strict total ordering           ==  {antisymmetric^~, asymmetric, transitive}
reflexive, transitive relation  ==  {reflexive, transitive}
\end{code}
As a side note, in mathematics, strict total orderings are sometimes defined using a property called {\em trichotomous}, which means that exactly one of |R(x,y)|, |x=y|, or |R(y,x)| must be true. However, when you clausify this property in the presence of transitivity, you end up with |antisymmetric^~| which says that at least one of |R(x,y)|, |x=y|, or |R(y,x)| must be true. However, there seems to be no standard name for the property |antisymmetric^~|.

((( TODO: Ann, can you add a table of how often these relations appear in the TPTP? )))

% ------------------------------------------------------------------------------
% - discovering relations

\section{Syntactic discovery of binary relations} \label{sec:discovery}

If our goal is to automatically choose the right treatment of equivalence relations, total orderings, etc., we must have an automatic way of identifying them in a given theory. It is easy to discover for example an equivalence relation in a theory by means of syntactic inspection. If we find the presence of the axioms |reflexive|, |symmetric|, and |transitive|, for the same relational symbol |R_|, we know that |R_| is a binary relation.

But there is a problem. There are other ways of axiomatizing equivalence relations. For example, a much more common way to axiomatize equivalence relations in the TPTP is to state the two properties |reflexive| and |euclidean| for |R_|\footnote{A possible reason for this is a paper written in the 1990s that argued for this alternative axiomatization. The first author of this paper has at one point seen this paper, but at the time of the writing, we have not been able to find it. If any reviewer knows which paper we are talking about, help would be appreciated.}. 

Rather than by hand enumerating all possible ways to axiomatize certain relations, we wrote a program that computes all possible ways for any combination of basic properties to imply any other combination of basic properties. Our program generates a table (shown in Appendix \ref{sec:implications}) that can be precomputed in a minute or so and used to very quickly detect any alternative axiomatization of binary relations using basic properties.

\begin{figure}[t]
\begin{center}
%include Implications/equivalences.tex
\end{center}
\vspace{-0.5cm}
\caption{Basic properties that are equivalent}
\label{fig:equivs}
\end{figure}

Let's explain how this table was generated. We start with a list of 32 basic properties (the 8 original basic properties, plus their negated, flipped, and negated flipped versions). Firstly, we use an automated theorem prover (we used E \cite{eprover}) to discover which of these are equivalent with other such properties. The result is displayed in Fig.\ \ref{fig:equivs}. Thus, 17 basic properties can be removed from the list, because they can be expressed using other properties. The list of basic properties now has 15 elements left.

Secondly, we want to generate all implications of the form |{prop1, .., propn} => prop| where the set |{prop1, .., propn}| is minimal (as displayed in Appendix \ref{sec:implications}). We do this separately for each |prop|. The procedure uses a simple constraint solver (SAT-solver) to keep track of all implications it has tried so far, and consists of one main loop. At every loop iteration, the constraint solver guesses a set |{prop1, .., propn}| from the set of all properties |P-{prop}|. The procedure then asks E whether or not |{prop1, .., propn} => prop| is valid. If it is, then we look at the proof that E produces, and print the implication |{propa, .., propb} => prop|, where |{propa, .., propb}| is the subset of properties that were used in the proof. We then also tell the constraint solver never to guess a superset of |{propa, .., propb}|. If the guessed implication can not be proven, we tell the constraint solver to never guess a subset of |{prop1, .., propn}|. The procedure stops when no guesses that satisfy all constraints can be made anymore. After the loop terminates, we may need to clean up the implications somewhat because some implications may subsume others. This procedure works well in practice, especially if all guesses are maximized according to their size.

To detect a binary relation |R_| with certain properties in a given theory, we simply gather all basic properties about |R_|, and compute which other properties they imply, using the pre-generated table. In this way, we never have to do any theorem proving in order to detect a binary relation with certain properties.

% ------------------------------------------------------------------------------
% - equivalence relations

\section{Dealing with equivalence relations}

equivalence relations

how to discover equivalence relations

how common are equivalence relations

how to encode equivalence relations + correctness proof

(partial equivalence relations

discover, how common

how to encode + proof)

% ------------------------------------------------------------------------------
% - dealing with total orderings

\section{Dealing with total orderings}

total orderings, strict total orderings

how to discover total orderings

how common are total orderings, strict total orderings

possible axiomatizations + correctness proof

encoding total orderings using ordering on the reals + proof

% ------------------------------------------------------------------------------
% - experimental results

\section{Experimental results}

\subsection{Equivalence relations}

original vs. equalified for E

original vs. equalified for Vampire

original vs. equalified for Z3

original vs. equalified for CVC4

original vs. equalified for Paradox - Satisfiable and Unsatisfiable

(original vs. p-equalified for E

original vs. p-equalified for Vampire

original vs. p-equalified for Z3

original vs. p-equalified for CVC4

original vs. p-equalified for Paradox - Satisfiable and Unsatisfiable)

\subsection{Total orderings}

total ordering vs. strict total ordering for E

total ordering vs. strict total ordering for Vampire

(total ordering/neg vs. strict total ordering/neg for E, Vampire

or some other comparisons)

total ordering vs. $\leq_\mathbb{R}$ for Z3

total ordering vs. $\leq_\mathbb{R}$ for CVC4

(Should we show

strict-total ordering vs. $\leq_\mathbb{R}$ for Z3

strict-total ordering vs. $\leq_\mathbb{R}$ for CVC4

separately? Only if the results differ.)

% ------------------------------------------------------------------------------
% - discussion and related work

\section{Discussion and Related Work}

chaining \cite{bachmair1998ordered}

...

% ------------------------------------------------------------------------------
% - conclusions and future work

\section{Conclusions and Future Work}

...

% ------------------------------------------------------------------------------
% - references

\bibliographystyle{plain}
\bibliography{main}

% ------------------------------------------------------------------------------
% - appendix

\appendix
\section{Implications between properties} \label{sec:implications}
Here follows the complete list of implications between properties that we discovered using the method described in Sect. \ref{sec:discovery}.

{\small
%{
%format <= = "\Leftarrow"
%include Implications/implications.tex
%}
}

\end{document}

