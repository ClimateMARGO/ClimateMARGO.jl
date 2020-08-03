# Optimization

## Supported optimization problems

The following optimization problems are currently supported in MARGO:
- Cost-benefit optimization
- Cost-effectiveness optimization

All of these constraints rely on the concept of discounting to convert a time-series of costs and benefits into a single scalar-valued objective function.

!!! ukw Time discounting
 Mathematically, a time-series ``g(t)`` is converted into a single scalar-valued function ``G`` by multiplying the time-series by a discount factor ``(1 - \rho)^{t-t_{0}}`` and integrating in time,
  ```math
  G = \int_{t_{0}}^{\infty}\, g(t) (1 - \rho)^{t-t_{0}}\, \text{d}t
  ```

  A great deal of the climate economic literature concerns methods (or philosophies) for determining the discount rate, with commonly cited values ranging all the way from 0% to 5%. Values larger than the growth rate of the economy result in de-valuing of future generations, which some argue is unethical.

  Discounting is also mathematically convenient because it generally guarantees the objective function is bounded, which makes interpreting (and numerically solving) the optimization problem a lot easier.

### Cost-benefit analysis

A natural and widely-used approach is cost-benefit analysis, in which the cost ``\mathcal{C}_{M, R, G, A}`` of deploying climate controls is balanced against the benefits ``\mathcal{B}_{M, R, G, A}`` of the avoided climate damages. Formally, we aim to maximize the net present benefits:
```math
    \max \left\{ \int_{t_{0}}^{t_{f}}
    \left(\mathcal{B}_{M, R, G, A} - \mathcal{C}_{M, R, G, A} \right) (1 + \rho)^{-(t-t_{0})} \, \text{d}t \right\},
```
where ``\rho`` is a social discount rate that determines the annual depreciation of future costs and benefits of climate control to society. There are different views about the appropriate non-zero discount rate to apply to multi-generational social utility. Here, we choose a discount rate of ``\rho = 1\%``, on the low end of values used in the literature, motivated by our preference towards inter-generational equity.

### Cost-effectiveness of keeping below a warming threshold

The conventional cost-benefit approach to understanding climate change is limited by the poorly understood damage function, which is likely to continue being revised as more is learned about its behavior at high levels of forcing. An alternative approach, which presently guides global climate policy negotiations, is to prescribe a threshold of climate damages– or temperatures, as in the Paris Climate Agreement– which is not to be surpassed.

In this implementation, we aim to find the lowest net present costs of control deployments
```math
    \min\left\{\int_{t_{0}}^{t_{f}} \mathcal{C}_{M,R,G,A} (1 + \rho)^{-(t-t_{0})} \text{ d}t\right\}
```
which keep controlled damages below the level corresponding to a chosen temperature threshold,
``\beta (T_{M,R,G})^{2} (1 - A(t)) < \beta (T^{\star})^{2}``, which we rewrite
```math
    T_{M,R,G,A} < T^{\star},
```
where ``T_{M,R,G,A}`` is the "adapted temperature".

## Additional constraints

For each control ``\alpha \in \mathcal{A} = \{ M, R, G, A\}``, we assert a maximum deployment rate
```math
    \abs{\dv{\alpha}{t}} \le \dot{\alpha},
```
as a crude parameterization of social, technological, and economic inertia, which acts to forbid implausibly aggressive deployment and phase-out scenarios (see Appendix A2 for more discussion). We set ``\dot{M} \equiv \dot{R} \equiv 1/40``years``^{-1}`` in line with the most ambitious climate goals and ``\dot{G} = 1/20``years``^{-1}`` to reflect the technological simplicity of attaining a large SRM forcing relative to mitigation and carbon dioxide removal. We interpret adaptation deployment costs as buying insurance against future damages at a fixed annual rate ``\mathcal{C}_{A} A^{2}``, with ``\dot{A} = 0``, which can be increased or decreased upon re-evaluation at a later date.

We also set a control readiness condition which optionally limits how soon each control is "ready" to be deployed. In particular, in the default configuration we set ``t_{R} = 2030`` and ``t_{G} = 2050`` because carbon dioxide removal has not yet been deployed at a climatically significant scale and solar radiation management does not yet exist as a socio-technological system.

## Optimization algorithm

We use the [Interior Point Optimizer](https://github.com/coin-or/Ipopt), an open source software package for large-scale nonlinear optimization, to minimize objective functions representing benefits and costs to society subject to assumed policy constraints. In practice, the control variables ``\alpha \in \mathcal{A} = \{ M, R, G, A\}`` are discretized into ``N = (t_{f} - t_{0}) / \delta t`` timesteps (default ``\delta t = 5`` years, ``N = 36``) resulting in a ``4N``-dimensional optimization problem. In the default (deterministic and convex) configuration, the model takes only ``\mathcal{O}(10 \text{ms})`` to solve after just-in-time compiling and effectively provides user feedback in real time.  This makes the model amenable to our forthcoming interactive web application, which is inspired by the impactful [En-ROADS model web application](https://en-roads.climateinteractive.org/scenario.html).
