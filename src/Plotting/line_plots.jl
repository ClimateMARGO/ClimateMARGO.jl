rcParams = PyPlot.PyDict(PyPlot.matplotlib."rcParams")
rcParams["lines.linewidth"] = 2. # Change linewidth

function fill_past(m, ylims)
    domain_idx = (t(m) .> m.present_year)
    fill_between(
        t(m)[.~domain_idx],
        ones(size(t(m)[.~domain_idx])) * ylims[1] * 2.,
        ones(size(t(m)[.~domain_idx])) * ylims[2] * 2.,
        facecolor="b", alpha=0.1
    )
    ylim(ylims)
    return
end

function plot_emissions(m::ClimateModel)
    title("effective greenhouse gas emissions")
    #fill_past(m, ylims)

    fill_between(t(m), effective_emissions(m), effective_emissions(m, M=true), facecolor="C0", alpha=0.3, label="Mitigation")
    fill_between(t(m), effective_emissions(m, M=true), effective_emissions(m, M=true, R=true), facecolor="C1", alpha=0.3, label="CDR")
    plot(t(m), effective_emissions(m), "-", color="grey", lw=2.25, label=L"$rq$ (no-policy baseline)")
    plot(t(m), effective_emissions(m, M=true), "k-", lw=1, alpha=0.4)
    plot(t(m), effective_emissions(m, M=true, R=true), "k-", lw=2.25, label=L"$rq(1-M) - rq_{0}R$ (controlled)")
    plot(t(m), zeros(size(t(m))), dashes=(2.5, 1.75), color="grey", alpha=0.5)

    ylimit = maximum(effective_emissions(m)) * 1.1
    ylims = [-ylimit, ylimit]
    ylabel(L"effective CO$_{2e}$ emissions [ppm / yr]")
    xlim(t(m)[1],2200.)
    ylim(minimum(effective_emissions(m, M=true, R=true))-5.,1.1*maximum(effective_emissions(m)))
    xticks(t(m)[1]:40.:2200.)
    xlabel("year")
    grid(true, alpha=0.3)
    return
end

function plot_concentrations(m::ClimateModel)
    title("greenhouse gas concentrations")
    #fill_past(m, ylims)

    fill_between(t(m), c(m), c(m, M=true), facecolor="C0", alpha=0.3, label="Mitigation")
    fill_between(t(m), c(m, M=true), c(m, M=true, R=true), facecolor="C1", alpha=0.3, label="CDR")
    plot(t(m), c(m), "-", color="grey", lw=2.25, label=L"$c$ (no-policy baseline)")
    plot(t(m), c(m, M=true), "k-", lw=1, alpha=0.4)
    plot(t(m), c(m, M=true, R=true), "k-", lw=2.25, label=L"$c_{M,R}$ (controlled)")
    ylims = [0., maximum(c(m))*1.05]
    ylabel(L"CO$_{2e}$ concentration [ppm]")
    xlabel("year")
    xlim(t(m)[1],2200.)
    ylim(ylims)
    xticks(t(m)[1]:40.:2200.)
    grid(true, alpha=0.3)
    return
end

function plot_forcings(m::ClimateModel; F0=3.)
    title("forcing (greenhouse effect and SRM)")
    #fill_past(m, ylims)

    fill_between(t(m), F(m, F0=F0), F(m, M=true, F0=F0), facecolor="C0", alpha=0.3, label="Mitigation")
    fill_between(t(m), F(m, M=true, F0=F0), F(m, M=true, R=true, F0=F0), facecolor="C1", alpha=0.3, label="CDR")
    fill_between(t(m), F(m, M=true, R=true, F0=F0), F(m, M=true, R=true, G=true, F0=F0), facecolor="C3", alpha=0.3, label="SRM")
    plot(t(m), F(m, F0=F0), "-", color="grey", lw=2.25, label=L"$F$ (no-policy baseline)")
    plot(t(m), F(m, M=true, F0=F0), "k-", lw=1, alpha=0.4)
    plot(t(m), F(m, M=true, R=true, F0=F0), "k-", lw=1, alpha=0.4)
    plot(t(m), F(m, M=true, R=true, G=true, F0=F0), "k-", lw=2.25, label=L"$F_{M,R,G}$ (controlled)")
    ylims = [0., maximum(F(m, F0=F0))*1.05]
    ylabel(L"radiative forcing [W/m$^{2}$]")
    xlabel("year")
    xlim(t(m)[1],2200.)
    ylim(ylims)
    xticks(t(m)[1]:40.:2200.)
    grid(true, alpha=0.3)
    return
end

function plot_temperatures(m::ClimateModel; temp_goal=1.2)
    title("adaptive temperature change")
    #fill_past(m, ylims)

    fill_between(t(m), T_adapt(m), T_adapt(m, M=true), facecolor="C0", alpha=0.3, label="Mitigation")
    fill_between(t(m), T_adapt(m, M=true), T_adapt(m, M=true, R=true), facecolor="C1", alpha=0.3, label="CDR")
    fill_between(t(m), T_adapt(m, M=true, R=true), T_adapt(m, M=true, R=true, G=true), facecolor="C3", alpha=0.3, label="SRM")
    fill_between(t(m), T_adapt(m, M=true, R=true, G=true), T_adapt(m, M=true, R=true, G=true, A=true), facecolor="C2", alpha=0.3, label="Adaptation")
    plot(t(m), T_adapt(m), "-", color="grey", lw=2.25, label=L"$T$ (no-policy baseline)")
    plot(t(m), T_adapt(m, M=true), "k-", lw=1, alpha=0.4)
    plot(t(m), T_adapt(m, M=true, R=true), "k-", lw=1, alpha=0.4)
    plot(t(m), T_adapt(m, M=true, R=true, G=true), "k-", lw=1., alpha=0.4)
    plot(t(m), T_adapt(m, M=true, R=true, G=true, A=true), "k-", lw=2.25, label=L"$T_{M,R,G,A}$ (adaptive)")
    plot(t(m),temp_goal .* ones(size(t(m))), dashes=(2.5, 1.75), color="grey", alpha=0.75, lw=2.5)
    ylims = [0., maximum(T_adapt(m)) * 1.05]
    ylabel("temperature anomaly [°C]")
    xlabel("year")
    xlim(t(m)[1],2200.)
    xticks(t(m)[1]:40.:2200.)
    grid(true, alpha=0.3)
    legend()
    return
end

function plot_controls(m::ClimateModel)
    title("optimized control deployments")
    plot(t(m)[m.economics.baseline_emissions .> 0.], m.controls.mitigate[m.economics.baseline_emissions .> 0.],
        color="C0", lw=2, label=L"$M$ (emissions mitigation)")
    plot(t(m), m.controls.remove, color="C1", lw=2, label=L"$R$ (carbon dioxide removal)")
    plot(t(m), m.controls.adapt, color="C2", lw=2, label=L"$A$ (adaptation)")
    plot(t(m), m.controls.geoeng, color="C3", lw=2, label=L"$G$ (solar geoengineering)")
    ylims = [0., 1.075]
    yticks(0.:0.2:1.0, 0:20:100)
    ylim(ylims)
    ylabel("control deployment [%]")
    xlabel("year")
    xlim(t(m)[1],2200.)
    xticks(t(m)[1]:40.:2200.)
    grid(true, alpha=0.3)
    return
end

function plot_benefits(m::ClimateModel; discounting=true)
    domain_idx = (t(m) .> m.domain.present_year)

    fill_between(
        t(m)[domain_idx],
        0 .*ones(size(t(m)))[domain_idx],
        net_benefit(m, discounting=discounting, M=true, R=true, G=true, A=true)[domain_idx],
        facecolor="grey", alpha=0.2
    )
    plot(t(m)[domain_idx], 0 .*ones(size(t(m)))[domain_idx], "-", lw=2, color="gray", label="no-policy baseline")
    plot(t(m)[domain_idx], benefit(m, discounting=discounting, M=true, R=true, G=true, A=true)[domain_idx], color="C8", lw=2, label="benefits (of avoided damages)")
    plot(t(m)[domain_idx], cost(m, discounting=discounting, M=true, R=true, G=true, A=true)[domain_idx], color="C4", lw=2, label="costs (of climate controls)")
    plot(t(m)[domain_idx], net_benefit(m, discounting=discounting, M=true, R=true, G=true, A=true)[domain_idx], color="k", lw=2, label="net benefits (benefits - costs)")
    ylabel(L"discounted costs and benefits [10$^{12}$ \$ / year]")
    xlabel("year")
    xlim(t(m)[1],2200.)
    xticks(t(m)[1]:40.:2200.)
    grid(true, alpha=0.3)
    title("cost-benefit analysis")
    return
end

function plot_damages(m::ClimateModel; discounting=true, percent_GWP=false, temp_goal=1.2)
    Enorm = deepcopy(E(m))/100.
    if ~percent_GWP; Enorm=1.; end;

    domain_idx = (t(m) .> m.domain.present_year)
    fill_between(
        t(m)[domain_idx],
        0 .*ones(size(t(m)))[domain_idx],
        (cost(m, discounting=discounting, M=true, R=true, G=true, A=true) ./ Enorm)[domain_idx],
        facecolor="C4", alpha=0.2
    )
    damages = damage(m, discounting=discounting, M=true, R=true, G=true, A=true)
    costs = cost(m, discounting=discounting, M=true, R=true, G=true, A=true)
    plot(t(m)[domain_idx], (damage(m, discounting=discounting) ./ Enorm)[domain_idx], color="gray", lw=2.25, label="uncontrolled damages")
    plot(t(m)[domain_idx], ((damages .+ costs)./ Enorm)[domain_idx], color="k", lw=2.25, label="net costs (controlled damages + controls)")
    plot(t(m)[domain_idx], (damages ./ Enorm)[domain_idx], color="C8", lw=2.25, label="controlled damages")
    plot(t(m)[domain_idx], (costs ./ Enorm)[domain_idx], color="C4", lw=2.25, label="cost of controls")

    ylim([0, maximum((damage(m, discounting=discounting) ./ Enorm)[domain_idx]) * 0.75])
    
    dmg_label = string("damage threshold at ",round(temp_goal, digits=2),L"°C with $A=0$")
    plot(
        t(m)[domain_idx],
        (damage(m.economics.β, E(m), temp_goal, discount=discount(m)) ./ Enorm)[domain_idx],
        dashes=(2.5,1.75), color="grey", alpha=0.75, lw=2.25, label=dmg_label
    )

    if ~percent_GWP;
        if ~discounting;
            ylabel(L"costs [10$^{12}$ \$ / year]");
        else;
            ylabel(L"discounted costs [10$^{12}$ \$ / year]");
        end
    else
        if ~discounting
            ylabel("costs [% GWP]")
        else
            ylabel("discounted costs [% GWP]")
            print("NOT YET SUPPORTED")
        end
    end

    xlabel("year")
    xlim(t(m)[1],2200.)
    xticks(t(m)[1]:40.:2200.)
    grid(true, alpha=0.175)
    title("costs of avoiding a damage threshold")
    legend()
    return
end

function plot_state(m::ClimateModel; new_figure=true, plot_legends=true, temp_goal=1.2)
    if new_figure
        fig, axs = subplots(2, 3, figsize=(14,8))
        axs = vcat(axs...)
    end

    sca(axs[1])
    plot_emissions(m)
    title("a)", loc="left")
    sca(axs[2])
    plot_concentrations(m)
    title("b)", loc="left")
    sca(axs[3])
    plot_temperatures(m, temp_goal=temp_goal)
    title("c)", loc="left")

    sca(axs[4])
    plot_controls(m)
    title("d)", loc="left")
    sca(axs[5])
    plot_benefits(m)
    title("e)", loc="left")
    sca(axs[6])
    plot_damages(m, temp_goal=temp_goal)
    title("f)", loc="left")

    if plot_legends;
        for ii in 1:6
            sca(axs[ii])
            if ii <= 2;
                legend(loc="lower left", labelspacing=0.14, handlelength=1.75);
            else
                legend(loc="upper left", labelspacing=0.14, handlelength=1.75);
            end
        end
    end
    tight_layout()

    return fig, axs
end
